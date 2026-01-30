import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'persistent_cache.dart';

class SupabaseService {
  static final SupabaseClient supabase = Supabase.instance.client;

  // ===== In-memory caches (hydrated from disk) =====

  static final ValueNotifier<Map<String, dynamic>?> currentUserProfileCache =
      ValueNotifier<Map<String, dynamic>?>(null);
  static String? _currentUserProfileCacheUserId;

  static final ValueNotifier<List<Map<String, dynamic>>?> favoriteTrainersCache =
      ValueNotifier<List<Map<String, dynamic>>?>(null);
  static String? _favoriteTrainersCacheUserId;

  static final ValueNotifier<({double lat, double lon})?> lastKnownLocation =
      ValueNotifier<({double lat, double lon})?>(null);

  static final ValueNotifier<String?> currentCityCache = ValueNotifier<String?>(null);
  static String? _currentCityCacheUserId;
  static ({double lat, double lon})? _currentCityLoc;

  // Chat caches (dashboard + per-conversation messages)
  static final ValueNotifier<List<Map<String, dynamic>>?> chatConversationsCache =
      ValueNotifier<List<Map<String, dynamic>>?>(null);
  static String? _chatConversationsCacheUserId;

  static final Map<String, ValueNotifier<List<Map<String, dynamic>>?>> _chatMessagesCache = {};
  static final Map<String, DateTime> _chatMessagesPersistLastAt = {};

  // Disk hydration guard
  static final Set<String> _diskHydratedUserIds = <String>{};

  // Throttling / single-flight
  static DateTime? _bootstrapRefreshLastAt;
  static Future<void>? _bootstrapRefreshInFlight;

  static DateTime? _chatRefreshLastAt;
  static Future<void>? _chatRefreshInFlight;

  // ===== Disk keys =====

  static String _kProfile(String userId) => 'cache:$userId:profile_v1';
  static String _kFavorites(String userId) => 'cache:$userId:favorites_v1';
  static String _kLocation(String userId) => 'cache:$userId:location_v1';
  static String _kCity(String userId) => 'cache:$userId:city_v1';
  static String _kChatConversations(String userId) => 'cache:$userId:chat_conversations_v1';
  static String _kChatMessages(String userId, String conversationId) =>
      'cache:$userId:chat_messages:$conversationId:v1';

  static bool _isDataUrl(String? s) => s != null && s.startsWith('data:image');

  static Map<String, dynamic> _compactProfileForDisk(Map<String, dynamic> p) {
    final out = Map<String, dynamic>.from(p);
    final main = out['main_photo_path'];
    if (main is String && _isDataUrl(main)) {
      out['main_photo_path'] = null;
    }
    // Avoid persisting huge arrays/base64.
    out.remove('profile_photos');
    out.remove('certificate_photos');
    out.remove('photos');
    out.remove('sub_photos');
    out.remove('trainee_photos');
    return out;
  }

  static List<Map<String, dynamic>> _compactProfilesForDisk(List<Map<String, dynamic>> list) {
    return list.map(_compactProfileForDisk).toList();
  }

  static Map<String, dynamic> _compactMessageForDisk(Map<String, dynamic> m) {
    // Messages are usually small; just clone.
    return Map<String, dynamic>.from(m);
  }

  static List<Map<String, dynamic>> _compactMessagesForDisk(List<Map<String, dynamic>> list) {
    // Keep last 200 for disk.
    final trimmed = list.length > 200 ? list.sublist(list.length - 200) : list;
    return trimmed.map(_compactMessageForDisk).toList();
  }

  static Future<void> _persistProfileToDisk(String userId, Map<String, dynamic> profile) async {
    await PersistentCache.setMap(_kProfile(userId), _compactProfileForDisk(profile));
  }

  static Future<void> _persistFavoritesToDisk(String userId, List<Map<String, dynamic>> favorites) async {
    await PersistentCache.setMapList(_kFavorites(userId), _compactProfilesForDisk(favorites));
  }

  static Future<void> _persistLocationToDisk(String userId, ({double lat, double lon}) loc) async {
    await PersistentCache.setMap(_kLocation(userId), {'lat': loc.lat, 'lon': loc.lon});
  }

  static Future<void> _persistCityToDisk(String userId, String city, ({double lat, double lon}) loc) async {
    await PersistentCache.setMap(_kCity(userId), {'city': city, 'lat': loc.lat, 'lon': loc.lon});
  }

  static Future<void> _persistChatConversationsToDisk(
    String userId,
    List<Map<String, dynamic>> conversations,
  ) async {
    // Drop large images if any.
    final compact = conversations.map((c) {
      final out = Map<String, dynamic>.from(c);
      final other = out['other_profile'];
      if (other is Map<String, dynamic>) {
        out['other_profile'] = _compactProfileForDisk(other);
      }
      return out;
    }).toList();
    await PersistentCache.setMapList(_kChatConversations(userId), compact);
  }

  static Future<void> _persistChatMessagesToDisk(
    String userId,
    String conversationId,
    List<Map<String, dynamic>> messages,
  ) async {
    await PersistentCache.setMapList(_kChatMessages(userId, conversationId), _compactMessagesForDisk(messages));
  }

  /// Clear in-memory caches on sign-out.
  static void clearInMemoryCaches() {
    _currentUserProfileCacheUserId = null;
    currentUserProfileCache.value = null;

    _favoriteTrainersCacheUserId = null;
    favoriteTrainersCache.value = null;

    lastKnownLocation.value = null;

    _currentCityCacheUserId = null;
    currentCityCache.value = null;
    _currentCityLoc = null;

    _chatConversationsCacheUserId = null;
    chatConversationsCache.value = null;
    _chatMessagesCache.clear();
    _chatMessagesPersistLastAt.clear();

    _diskHydratedUserIds.clear();
  }

  /// Load cached profile/favorites/location/city/chat-conversations from disk into memory.
  static Future<void> hydrateCachesFromDisk(String userId) async {
    if (_diskHydratedUserIds.contains(userId)) return;
    _diskHydratedUserIds.add(userId);

    try {
      final profile = await PersistentCache.getMap(_kProfile(userId));
      if (profile != null) {
        _currentUserProfileCacheUserId = userId;
        currentUserProfileCache.value = Map<String, dynamic>.from(profile);
      }
    } catch (_) {}

    try {
      final favorites = await PersistentCache.getMapList(_kFavorites(userId));
      if (favorites != null) {
        _favoriteTrainersCacheUserId = userId;
        favoriteTrainersCache.value = favorites;
      }
    } catch (_) {}

    try {
      final loc = await PersistentCache.getMap(_kLocation(userId));
      final lat = (loc?['lat'] as num?)?.toDouble();
      final lon = (loc?['lon'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        lastKnownLocation.value = (lat: lat, lon: lon);
      }
    } catch (_) {}

    try {
      final cityMap = await PersistentCache.getMap(_kCity(userId));
      final city = (cityMap?['city'] as String?)?.trim();
      final lat = (cityMap?['lat'] as num?)?.toDouble();
      final lon = (cityMap?['lon'] as num?)?.toDouble();
      if (city != null && city.isNotEmpty) {
        _currentCityCacheUserId = userId;
        currentCityCache.value = city;
        if (lat != null && lon != null) {
          _currentCityLoc = (lat: lat, lon: lon);
        }
      }
    } catch (_) {}

    try {
      final convs = await PersistentCache.getMapList(_kChatConversations(userId));
      if (convs != null) {
        _chatConversationsCacheUserId = userId;
        chatConversationsCache.value = convs;
      }
    } catch (_) {}
  }

  /// Persist last known location, and clear city cache when location changes significantly (~1km).
  static Future<void> setLastKnownLocationForCurrentUser({
    required double lat,
    required double lon,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final prev = lastKnownLocation.value;
    lastKnownLocation.value = (lat: lat, lon: lon);
    await _persistLocationToDisk(userId, (lat: lat, lon: lon));

    if (prev != null) {
      final meters = Geolocator.distanceBetween(prev.lat, prev.lon, lat, lon);
      if (meters > 1000) {
        // Invalidate city cache when moving.
        currentCityCache.value = null;
        _currentCityLoc = null;
        if (_currentCityCacheUserId == userId) {
          await PersistentCache.remove(_kCity(userId));
        }
      }
    }
  }

  static Future<void> setCityForCurrentUser({
    required String city,
    required double lat,
    required double lon,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    _currentCityCacheUserId = userId;
    currentCityCache.value = trimmed;
    _currentCityLoc = (lat: lat, lon: lon);
    await _persistCityToDisk(userId, trimmed, (lat: lat, lon: lon));
  }

  /// 프로필 생성/업데이트 (온보딩 저장용)
  static Future<void> upsertProfile(Map<String, dynamic> profile) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final payload = Map<String, dynamic>.from(profile);
    payload['user_id'] = user.id;
    payload['updated_at'] = DateTime.now().toIso8601String();

    await supabase.from('profiles').upsert(payload, onConflict: 'user_id');
  }

  /// 공개 프로필 가져오기 (공유/상대방 프로필)
  static Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Failed to get public profile: $e');
      return null;
    }
  }

  /// 좋아요(즐겨찾기) 삭제
  static Future<void> removeFavorite({
    required String currentUserId,
    required String swipedUserId,
  }) async {
    await supabase
        .from('matches')
        .delete()
        .eq('user_id', currentUserId)
        .eq('swiped_user_id', swipedUserId);
  }

  /// 사용자 타입에 따른 conversation 목록 (trainer_id/trainee_id)
  static Future<List<Map<String, dynamic>>> getUserConversations(
    String userId,
    String userType,
  ) async {
    try {
      final normalized = userType.trim().toLowerCase();
      dynamic response;
      if (normalized == 'trainer') {
        response = await supabase.from('conversations').select().eq('trainer_id', userId);
      } else if (normalized == 'trainee') {
        response = await supabase.from('conversations').select().eq('trainee_id', userId);
      } else {
        response = await supabase
            .from('conversations')
            .select()
            .or('trainer_id.eq.$userId,trainee_id.eq.$userId');
      }

      if (response is! List) return [];
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Failed to get conversations: $e');
      return [];
    }
  }

  /// conversation 1개 조회
  static Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final response = await supabase
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Failed to get conversation: $e');
      return null;
    }
  }

  /// 최신 메시지 1개
  static Future<Map<String, dynamic>?> getLatestMessage(String conversationId) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1);
      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }
      return null;
    } catch (e) {
      print('Failed to get latest message: $e');
      return null;
    }
  }

  /// request 타입 메시지 1개 (없으면 null)
  static Future<Map<String, dynamic>?> getRequestMessage(String conversationId) async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('type', 'request')
          .order('created_at', ascending: true)
          .limit(1);
      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }
      return null;
    } catch (e) {
      print('Failed to get request message: $e');
      return null;
    }
  }

  /// conversation 내 unread count (상대가 보낸 is_read=false)
  static Future<int> getUnreadMessageCount(String conversationId, String currentUserId) async {
    try {
      final response = await supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
      if (response is List) return response.length;
      return 0;
    } catch (e) {
      // is_read 컬럼이 없다면 0으로 fallback
      print('Failed to get unread count (fallback 0): $e');
      return 0;
    }
  }

  /// 전체 unread 합계
  static Future<int> getTotalUnreadMessageCount(String userId, String userType) async {
    try {
      final conversations = await getUserConversations(userId, userType);
      int total = 0;
      for (final c in conversations) {
        final id = c['id'] as String?;
        if (id == null) continue;
        total += await getUnreadMessageCount(id, userId);
      }
      return total;
    } catch (e) {
      print('Failed to get total unread count: $e');
      return 0;
    }
  }

  /// 메시지 목록 (created_at ASC)
  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int? limit,
  }) async {
    try {
      if (limit != null) {
        // Fetch newest N, then reverse so UI gets oldest→newest.
        final dynamic response = await supabase
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(limit);
        if (response is! List) return [];
        final list = response.map((e) => Map<String, dynamic>.from(e)).toList();
        return list.reversed.toList();
      }

      final dynamic response = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      if (response is! List) return [];
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Failed to get messages: $e');
      return [];
    }
  }

  /// 메시지 보내기 (type: text/system/request)
  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String messageText,
    required String type,
  }) async {
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_text': messageText,
      'type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 상대가 보낸 메시지 읽음 처리
  static Future<void> markMessagesAsRead(String conversationId, String currentUserId) async {
    try {
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      // ignore if schema doesn't have is_read
      print('Failed to mark messages as read (ignored): $e');
    }
  }

  /// training request 생성: conversation 없으면 생성, request 메시지 insert
  static Future<String> sendTrainingRequest({
    required String trainerId,
    required String traineeId,
    required String skill,
    required String method,
  }) async {
    // 1) existing conversation?
    final existing = await supabase
        .from('conversations')
        .select()
        .eq('trainer_id', trainerId)
        .eq('trainee_id', traineeId)
        .order('created_at', ascending: false)
        .limit(1);

    String conversationId;
    if (existing is List && existing.isNotEmpty) {
      conversationId = existing.first['id'] as String;
    } else {
      final created = await supabase
          .from('conversations')
          .insert({
            'trainer_id': trainerId,
            'trainee_id': traineeId,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      conversationId = created['id'] as String;
    }

    await sendMessage(
      conversationId: conversationId,
      senderId: traineeId,
      messageText: 'Request: $skill ($method)',
      type: 'request',
    );
    return conversationId;
  }

  static Future<void> acceptTrainingRequest(String conversationId) async {
    await supabase
        .from('conversations')
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  static Future<void> declineTrainingRequest(String conversationId) async {
    await supabase
        .from('conversations')
        .update({'status': 'declined', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  // ===== Chat (cache-first) =====

  static Future<List<Map<String, dynamic>>> getUserConversationsUnified(String userId) async {
    try {
      final response = await supabase
          .from('conversations')
          .select()
          .or('trainer_id.eq.$userId,trainee_id.eq.$userId');
      if (response is! List) return [];
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Failed to get unified conversations: $e');
      return [];
    }
  }

  static void _sortDashboardConversations(List<Map<String, dynamic>> list) {
    DateTime? latestAt(Map<String, dynamic> c) {
      final lm = c['latest_message'];
      if (lm is Map) {
        final ts = lm['created_at'] as String?;
        return ts == null ? null : DateTime.tryParse(ts);
      }
      return null;
    }

    list.sort((a, b) {
      final aUnread = (a['unread_count'] as num?)?.toInt() ?? 0;
      final bUnread = (b['unread_count'] as num?)?.toInt() ?? 0;
      if (aUnread > 0 && bUnread == 0) return -1;
      if (aUnread == 0 && bUnread > 0) return 1;
      final aAt = latestAt(a) ?? DateTime.tryParse((a['updated_at'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = latestAt(b) ?? DateTime.tryParse((b['updated_at'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
  }

  static Future<List<Map<String, dynamic>>> _fetchChatConversationsWithDetails(String userId) async {
    // Prefer RPC if installed.
    try {
      final res = await supabase.rpc('get_dashboard_conversations');
      if (res is List) {
        return res.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          // Normalize jsonb maps if needed.
          if (m['other_profile'] is Map) {
            m['other_profile'] = Map<String, dynamic>.from(m['other_profile'] as Map);
          }
          if (m['latest_message'] is Map) {
            m['latest_message'] = Map<String, dynamic>.from(m['latest_message'] as Map);
          }
          if (m['request_message'] is Map) {
            m['request_message'] = Map<String, dynamic>.from(m['request_message'] as Map);
          }
          return m;
        }).toList();
      }
    } catch (_) {
      // ignore; fallback below
    }

    // Fallback: N+1 enrichment
    final currentUser = supabase.auth.currentUser;
    final convs = await getUserConversationsUnified(userId);
    final out = <Map<String, dynamic>>[];
    for (final conv in convs) {
      final convId = conv['id'] as String?;
      if (convId == null) continue;
      final trainerId = conv['trainer_id'] as String?;
      final traineeId = conv['trainee_id'] as String?;
      final otherUserId = (trainerId == userId) ? traineeId : trainerId;
      final otherProfile =
          (otherUserId == null || otherUserId.isEmpty) ? null : await getPublicProfile(otherUserId);
      final latestMessage = await getLatestMessage(convId);
      final requestMessage = await getRequestMessage(convId);
      final unreadCount =
          currentUser == null ? 0 : await getUnreadMessageCount(convId, currentUser.id);
      final isRequester = (traineeId ?? '') == userId;
      out.add({
        ...conv,
        'latest_message': latestMessage,
        'request_message': requestMessage,
        'unread_count': unreadCount,
        'other_profile': otherProfile,
        'is_requester': isRequester,
        'other_user_id': otherUserId,
      });
    }
    _sortDashboardConversations(out);
    return out;
  }

  static String _fingerprintDashboard(List<Map<String, dynamic>> list) {
    final parts = list.map((c) {
      final id = c['id']?.toString() ?? '';
      final updated = c['updated_at']?.toString() ?? '';
      final status = c['status']?.toString() ?? '';
      final unread = (c['unread_count'] as num?)?.toInt() ?? 0;
      final lm = c['latest_message'];
      final lmId = (lm is Map) ? (lm['id']?.toString() ?? '') : '';
      final lmAt = (lm is Map) ? (lm['created_at']?.toString() ?? '') : '';
      final sched = c['schedule_state']?.toString() ?? '';
      return '$id|$updated|$status|$unread|$lmId|$lmAt|$sched';
    }).toList()
      ..sort();
    return parts.join('~');
  }

  static Future<List<Map<String, dynamic>>> getChatConversationsCached(
    String userId, {
    bool forceRefresh = false,
  }) async {
    await hydrateCachesFromDisk(userId);

    final cached = chatConversationsCache.value;
    if (!forceRefresh && _chatConversationsCacheUserId == userId && cached != null) {
      Future.microtask(() => refreshChatConversationsIfChanged(userId));
      return cached;
    }

    final fresh = await _fetchChatConversationsWithDetails(userId);
    _chatConversationsCacheUserId = userId;
    chatConversationsCache.value = fresh;
    await _persistChatConversationsToDisk(userId, fresh);
    return fresh;
  }

  static Future<void> refreshChatConversationsIfChanged(String userId) async {
    // throttle: 3s
    final now = DateTime.now();
    if (_chatRefreshLastAt != null && now.difference(_chatRefreshLastAt!).inSeconds < 3) {
      return _chatRefreshInFlight ?? Future.value();
    }
    if (_chatRefreshInFlight != null) return _chatRefreshInFlight!;

    final completer = Completer<void>();
    _chatRefreshInFlight = completer.future;
    _chatRefreshLastAt = now;

    () async {
      try {
        final before = chatConversationsCache.value ?? const <Map<String, dynamic>>[];
        final beforeFp = _fingerprintDashboard(before.toList());
        final fresh = await _fetchChatConversationsWithDetails(userId);
        final afterFp = _fingerprintDashboard(fresh);
        if (afterFp != beforeFp) {
          _chatConversationsCacheUserId = userId;
          chatConversationsCache.value = fresh;
          await _persistChatConversationsToDisk(userId, fresh);
        }
      } catch (e) {
        print('refreshChatConversationsIfChanged failed: $e');
      } finally {
        _chatRefreshInFlight = null;
        completer.complete();
      }
    }();

    return completer.future;
  }

  static ValueNotifier<List<Map<String, dynamic>>?> chatMessagesCacheForConversation(String conversationId) {
    return _chatMessagesCache.putIfAbsent(
      conversationId,
      () => ValueNotifier<List<Map<String, dynamic>>?>(null),
    );
  }

  static Future<void> hydrateChatMessagesFromDisk(String userId, String conversationId) async {
    final notifier = chatMessagesCacheForConversation(conversationId);
    if (notifier.value != null) return;
    final list = await PersistentCache.getMapList(_kChatMessages(userId, conversationId));
    if (list != null) notifier.value = list;
  }

  static Future<List<Map<String, dynamic>>> getChatMessagesCached(
    String userId,
    String conversationId, {
    bool forceRefresh = false,
    int limit = 200,
  }) async {
    await hydrateChatMessagesFromDisk(userId, conversationId);

    final notifier = chatMessagesCacheForConversation(conversationId);
    final cached = notifier.value;
    if (!forceRefresh && cached != null) {
      return cached;
    }

    final fresh = await getMessages(conversationId, limit: limit);
    notifier.value = fresh;
    await _persistChatMessagesToDisk(userId, conversationId, fresh);
    return fresh;
  }

  static void upsertChatMessageIntoCache({
    required String userId,
    required String conversationId,
    required Map<String, dynamic> message,
  }) {
    final notifier = chatMessagesCacheForConversation(conversationId);
    final list = List<Map<String, dynamic>>.from(notifier.value ?? const []);
    final id = message['id']?.toString();

    int idx = -1;
    if (id != null && id.isNotEmpty) {
      idx = list.indexWhere((m) => m['id']?.toString() == id);
    }
    if (idx >= 0) {
      list[idx] = Map<String, dynamic>.from(message);
    } else {
      list.add(Map<String, dynamic>.from(message));
    }

    list.sort((a, b) {
      final aAt = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aAt.compareTo(bAt);
    });

    notifier.value = list;

    final last = _chatMessagesPersistLastAt[conversationId];
    final now = DateTime.now();
    if (last == null || now.difference(last).inSeconds >= 2) {
      _chatMessagesPersistLastAt[conversationId] = now;
      Future.microtask(() => _persistChatMessagesToDisk(userId, conversationId, list));
    }
  }

  // ===== Scheduling (conversation-level state) =====

  /// Requires `MIGRATE_CONVERSATIONS_SCHEDULE.sql` applied in DB.
  static Future<Map<String, dynamic>?> respondToConversationSchedule({
    required String conversationId,
    required DateTime proposedStartLocal,
    required DateTime proposedEndLocal,
    required bool agree,
  }) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return null;

    final conv = await getConversation(conversationId);
    if (conv == null) return null;

    final trainerId = conv['trainer_id'] as String?;
    final traineeId = conv['trainee_id'] as String?;
    final isTrainer = trainerId != null && trainerId == currentUser.id;
    final isTrainee = traineeId != null && traineeId == currentUser.id;
    if (!isTrainer && !isTrainee) return null;

    final proposedStartUtc = proposedStartLocal.toUtc();
    final proposedEndUtc = proposedEndLocal.toUtc();

    bool? trainerAgreed = conv['trainer_schedule_agreed'] as bool?;
    bool? traineeAgreed = conv['trainee_schedule_agreed'] as bool?;
    final existingStartStr = conv['scheduled_start_time'] as String?;
    final existingState = conv['schedule_state'] as String?;

    DateTime? existingStartUtc;
    if (existingStartStr != null && existingStartStr.isNotEmpty) {
      existingStartUtc = DateTime.tryParse(existingStartStr)?.toUtc();
    }

    final isDifferentProposal = existingStartUtc == null ||
        existingStartUtc.difference(proposedStartUtc).inMinutes.abs() >= 1 ||
        existingState == null ||
        existingState == 'declined';

    if (isDifferentProposal) {
      trainerAgreed = null;
      traineeAgreed = null;
    }

    if (isTrainer) trainerAgreed = agree;
    if (isTrainee) traineeAgreed = agree;

    String newState = 'proposed';
    if (agree == false) {
      newState = 'declined';
    } else if (trainerAgreed == true && traineeAgreed == true) {
      newState = 'agreed';
    }

    final update = {
      'scheduled_start_time': proposedStartUtc.toIso8601String(),
      'scheduled_end_time': proposedEndUtc.toIso8601String(),
      'schedule_state': newState,
      'trainer_schedule_agreed': trainerAgreed,
      'trainee_schedule_agreed': traineeAgreed,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final updated = await supabase
        .from('conversations')
        .update(update)
        .eq('id', conversationId)
        .select()
        .maybeSingle();
    if (updated == null) return null;
    return Map<String, dynamic>.from(updated);
  }

  /// calendar_events: 이벤트 생성
  static Future<void> createCalendarEvent({
    required String userId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? conversationId,
  }) async {
    await supabase.from('calendar_events').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'conversation_id': conversationId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// calendar_events: 기간 조회
  static Future<List<Map<String, dynamic>>> getCalendarEvents({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String())
          .lt('start_time', endDate.toIso8601String())
          .order('start_time', ascending: true);

      if (response is! List) return [];
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Failed to get calendar events: $e');
      return [];
    }
  }

  /// GlobalTalentMatchingScreen 지원: 키워드 기반 global cards (거리 없이)
  static Future<List<Map<String, dynamic>>> getTalentMatchingCards({
    required String userType,
    required List<String> userTalentsOrGoals,
    required String currentUserId,
    int limit = 100,
  }) async {
    try {
      final targetType = userType == 'trainer' ? 'trainee' : 'trainer';

      // already swiped
      final swiped = await supabase
          .from('matches')
          .select('swiped_user_id')
          .eq('user_id', currentUserId);
      final swipedIds = <String>{};
      if (swiped is List) {
        for (final e in swiped) {
          final id = (e as Map)['swiped_user_id'] as String?;
          if (id != null && id.isNotEmpty) swipedIds.add(id);
        }
      }

      final response = await supabase
          .from('profiles')
          .select()
          .eq('user_type', targetType)
          .neq('user_id', currentUserId)
          .limit(limit);
      if (response is! List) return [];

      final keywords = userTalentsOrGoals.map((e) => e.toLowerCase()).toSet();
      final list = response
          .map((e) => Map<String, dynamic>.from(e))
          .where((p) {
            final id = p['user_id'] as String? ?? '';
            return id.isNotEmpty && !swipedIds.contains(id);
          })
          .toList();

      int matchCount(Map<String, dynamic> p) {
        final raw = (p['talents'] as List<dynamic>?) ?? [];
        final set = raw.map((e) => e.toString().toLowerCase()).toSet();
        return set.intersection(keywords).length;
      }

      // sort by match count desc
      list.sort((a, b) => matchCount(b).compareTo(matchCount(a)));
      return list;
    } catch (e) {
      print('Failed to get talent matching cards: $e');
      return [];
    }
  }

  /// matches 테이블에 매치 데이터 저장
  /// [swipedUserId]: 스와이프한 유저의 ID
  /// [currentUserId]: 현재 로그인한 유저의 ID
  /// [isMatch]: 매치 여부 (true: 좋아요, false: 싫어요)
  static Future<void> saveMatch({
    required String swipedUserId,
    required String currentUserId,
    required bool isMatch,
  }) async {
    print('========================================');
    print('SupabaseService.saveMatch 시작');
    print('  - currentUserId: $currentUserId');
    print('  - swipedUserId: $swipedUserId');
    print('  - isMatch: $isMatch');
    
    try {
      // 저장할 데이터 준비
      final insertData = {
        'user_id': currentUserId,
        'swiped_user_id': swipedUserId,
        'is_match': isMatch,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      print('저장할 데이터:');
      print('  $insertData');
      
      // 현재 인증된 사용자 확인
      final currentAuthUser = supabase.auth.currentUser;
      print('현재 인증된 사용자:');
      print('  - ID: ${currentAuthUser?.id}');
      print('  - Email: ${currentAuthUser?.email}');
      print('  - Session 존재: ${currentAuthUser != null}');
      
      if (currentAuthUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // user_id가 현재 인증된 사용자와 일치하는지 확인
      if (currentUserId != currentAuthUser.id) {
        print('⚠ 경고: currentUserId($currentUserId)와 auth.currentUser.id(${currentAuthUser.id})가 일치하지 않습니다!');
        print('  -> auth.currentUser.id를 사용합니다.');
      }
      
      // upsert 사용 (이미 존재하면 업데이트, 없으면 삽입)
      print('Supabase upsert 실행 전...');
      print('  테이블: matches');
      print('  데이터: $insertData');
      
      final result = await supabase
          .from('matches')
          .upsert(
            insertData,
            onConflict: 'user_id,swiped_user_id',
          )
          .select();
      
      print('Supabase upsert 실행 완료');
      print('반환된 결과 타입: ${result.runtimeType}');
      print('반환된 결과: $result');
      
      if (result != null) {
        if (result is List) {
          if (result.isNotEmpty) {
            print('✓ 저장 성공: 데이터가 반환되었습니다');
            print('  반환된 레코드 수: ${result.length}');
            print('  첫 번째 레코드: ${result[0]}');
          } else {
            print('⚠ 경고: 빈 리스트가 반환되었습니다');
          }
        } else {
          print('✓ 저장 성공: 데이터가 반환되었습니다');
          print('  반환된 데이터: $result');
        }
      } else {
        print('⚠ 경고: null이 반환되었습니다');
      }
      
      print('========================================');
    } catch (e, stackTrace) {
      print('========================================');
      print('✗ SupabaseService.saveMatch 실패');
      print('  - Error: $e');
      print('  - Error Type: ${e.runtimeType}');
      print('  - Error toString: ${e.toString()}');
      
      // PostgrestException인 경우 상세 정보 출력
      if (e.toString().contains('PostgrestException') || 
          e.toString().contains('postgres') ||
          e.toString().contains('RLS') ||
          e.toString().contains('policy')) {
        print('  - 이것은 데이터베이스 오류입니다!');
        print('  - RLS 정책이나 테이블 구조를 확인하세요.');
        print('  - matches 테이블의 RLS 정책이 올바르게 설정되었는지 확인하세요.');
      }
      
      print('  - StackTrace: $stackTrace');
      print('========================================');
      rethrow;
    }
  }

  /// 현재 사용자의 프로필 가져오기
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('프로필 가져오기 실패: $e');
      return null;
    }
  }

  static void _sortByName(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final an = (a['name'] as String? ?? '').trim().toLowerCase();
      final bn = (b['name'] as String? ?? '').trim().toLowerCase();
      return an.compareTo(bn);
    });
  }

  static Future<Map<String, dynamic>?> _fetchProfileByUserId(String userId) async {
    final response = await supabase.from('profiles').select().eq('user_id', userId).maybeSingle();
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>?> getCurrentUserProfileCached(
    String userId, {
    bool forceRefresh = false,
  }) async {
    await hydrateCachesFromDisk(userId);

    final cached = currentUserProfileCache.value;
    if (!forceRefresh && _currentUserProfileCacheUserId == userId && cached != null) {
      // Background refresh only if changed.
      Future.microtask(() => refreshBootstrapCachesIfChanged(userId));
      return cached;
    }

    final fresh = await _fetchProfileByUserId(userId);
    if (fresh == null) return null;
    _currentUserProfileCacheUserId = userId;
    currentUserProfileCache.value = fresh;
    await _persistProfileToDisk(userId, fresh);
    return fresh;
  }

  static Future<Map<String, dynamic>?> refreshCurrentUserProfileCache(String userId) async {
    final fresh = await _fetchProfileByUserId(userId);
    if (fresh == null) return null;
    _currentUserProfileCacheUserId = userId;
    currentUserProfileCache.value = fresh;
    await _persistProfileToDisk(userId, fresh);
    return fresh;
  }

  static Future<List<Map<String, dynamic>>> _fetchFavoriteTrainersFromDb(String userId) async {
    final matchesResponse = await supabase
        .from('matches')
        .select('swiped_user_id')
        .eq('user_id', userId)
        .eq('is_match', true);

    if (matchesResponse is! List) return [];
    final likedUserIds = matchesResponse
        .map((e) => Map<String, dynamic>.from(e)['swiped_user_id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (likedUserIds.isEmpty) return [];

    final profilesResponse =
        await supabase.from('profiles').select().inFilter('user_id', likedUserIds);
    if (profilesResponse is! List) return [];
    final profiles = profilesResponse.map((e) => Map<String, dynamic>.from(e)).toList();
    _sortByName(profiles);
    return profiles;
  }

  static Future<List<Map<String, dynamic>>> getFavoriteTrainersCached(
    String userId, {
    bool forceRefresh = false,
  }) async {
    await hydrateCachesFromDisk(userId);

    final cached = favoriteTrainersCache.value;
    if (!forceRefresh && _favoriteTrainersCacheUserId == userId && cached != null) {
      Future.microtask(() => refreshBootstrapCachesIfChanged(userId));
      return cached;
    }

    final fresh = await _fetchFavoriteTrainersFromDb(userId);
    _favoriteTrainersCacheUserId = userId;
    favoriteTrainersCache.value = fresh;
    await _persistFavoritesToDisk(userId, fresh);
    return fresh;
  }

  /// Throttled background refresh: only updates caches if DB changed.
  static Future<void> refreshBootstrapCachesIfChanged(String userId) async {
    // throttle: 5s
    final now = DateTime.now();
    if (_bootstrapRefreshLastAt != null && now.difference(_bootstrapRefreshLastAt!).inSeconds < 5) {
      return _bootstrapRefreshInFlight ?? Future.value();
    }
    if (_bootstrapRefreshInFlight != null) return _bootstrapRefreshInFlight!;

    final completer = Completer<void>();
    _bootstrapRefreshInFlight = completer.future;
    _bootstrapRefreshLastAt = now;

    () async {
      try {
        // Profile updated_at fingerprint
        final profRow = await supabase
            .from('profiles')
            .select('updated_at')
            .eq('user_id', userId)
            .maybeSingle();
        final dbUpdatedAt = (profRow?['updated_at'] as String?)?.trim();
        final cacheUpdatedAt = (currentUserProfileCache.value?['updated_at'] as String?)?.trim();
        final profileChanged =
            dbUpdatedAt != null && dbUpdatedAt.isNotEmpty && dbUpdatedAt != cacheUpdatedAt;

        // Favorites swiped ids fingerprint
        final matches = await supabase
            .from('matches')
            .select('swiped_user_id')
            .eq('user_id', userId)
            .eq('is_match', true);
        final dbIds = <String>[];
        if (matches is List) {
          for (final e in matches) {
            final id = (e as Map)['swiped_user_id'] as String?;
            if (id != null && id.isNotEmpty) dbIds.add(id);
          }
        }
        dbIds.sort();
        final cachedFavIds = (favoriteTrainersCache.value ?? const <Map<String, dynamic>>[])
            .map((p) => p['user_id'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList()
          ..sort();
        final favoritesChanged = jsonEncode(dbIds) != jsonEncode(cachedFavIds);

        if (profileChanged) {
          final fresh = await _fetchProfileByUserId(userId);
          if (fresh != null) {
            _currentUserProfileCacheUserId = userId;
            currentUserProfileCache.value = fresh;
            await _persistProfileToDisk(userId, fresh);
          }
        }

        if (favoritesChanged) {
          final freshFav = dbIds.isEmpty ? <Map<String, dynamic>>[] : await _fetchFavoriteTrainersFromDb(userId);
          _favoriteTrainersCacheUserId = userId;
          favoriteTrainersCache.value = freshFav;
          await _persistFavoritesToDisk(userId, freshFav);
        }
      } catch (e) {
        print('refreshBootstrapCachesIfChanged failed: $e');
      } finally {
        _bootstrapRefreshInFlight = null;
        completer.complete();
      }
    }();

    return completer.future;
  }

  /// 현재 사용자의 위치 정보 업데이트
  /// [latitude]: 위도
  /// [longitude]: 경도
  static Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      print('위치 정보 업데이트 시작');
      print('  - User ID: ${user.id}');
      print('  - Latitude: $latitude');
      print('  - Longitude: $longitude');

      await supabase
          .from('profiles')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      print('✓ 위치 정보 업데이트 완료');
    } catch (e) {
      print('위치 정보 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 사용자 타입에 따라 매칭할 카드 목록 가져오기 (거리 기반 정렬)
  /// Supabase RPC 함수를 사용하여 서버에서 거리 계산 및 정렬 처리
  /// [userType]: 'trainer' 또는 'trainee'
  /// [currentLatitude]: 현재 사용자의 위도
  /// [currentLongitude]: 현재 사용자의 경도
  /// [userTalentsOrGoals]: Trainer의 경우 talents, Trainee의 경우 goals (현재는 사용하지 않지만 호환성을 위해 유지)
  static Future<List<Map<String, dynamic>>> getMatchingCards({
    required String userType,
    required double currentLatitude,
    required double currentLongitude,
    required List<String> userTalentsOrGoals,
    required String currentUserId,
  }) async {
    try {
      // Supabase RPC 함수 호출로 거리 계산 및 정렬을 서버에서 처리
      final response = await supabase.rpc(
        'get_nearby_profiles',
        params: {
          'p_user_id': currentUserId,
          'p_user_type': userType,
          'p_latitude': currentLatitude,
          'p_longitude': currentLongitude,
          'p_limit': 100, // 최대 100명까지 가져오기
        },
      );

      if (response is List) {
        final cards = response
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        
        // 거리 순 정렬 확인 로그
        if (cards.isNotEmpty) {
          print('========================================');
          print('거리 순 정렬 확인:');
          for (int i = 0; i < cards.length && i < 5; i++) {
            final distance = (cards[i]['distance_meters'] as num?)?.toDouble();
            final name = cards[i]['name'] as String? ?? 'Unknown';
            print('  ${i + 1}. $name: ${distance?.toStringAsFixed(1) ?? 'N/A'}m');
          }
          print('========================================');
        }
        
        return cards;
      }
      
      print('RPC 함수 응답이 List가 아님: ${response.runtimeType}');
      return [];
    } catch (e) {
      print('카드 가져오기 실패 (RPC): $e');
      print('Fallback: 기존 방식으로 시도...');
      
      // Fallback: 기존 방식으로 처리 (RPC 함수가 없거나 오류 발생 시)
      return _getMatchingCardsFallback(
        userType: userType,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        currentUserId: currentUserId,
      );
    }
  }

  /// Fallback: 기존 방식으로 카드 가져오기 (RPC 함수 사용 불가 시)
  static Future<List<Map<String, dynamic>>> _getMatchingCardsFallback({
    required String userType,
    required double currentLatitude,
    required double currentLongitude,
    required String currentUserId,
  }) async {
    try {
      // 이미 스와이프한 사용자 ID 목록 가져오기
      List<String> swipedUserIds = [];
      try {
        final swipedResponse = await supabase
            .from('matches')
            .select('swiped_user_id')
            .eq('user_id', currentUserId);

        if (swipedResponse is List) {
          swipedUserIds = swipedResponse
              .map((e) {
                final map = Map<String, dynamic>.from(e);
                return map['swiped_user_id'] as String? ?? '';
              })
              .where((id) => id.isNotEmpty)
              .toList();
        }
      } catch (e) {
        print('스와이프 기록 가져오기 실패: $e');
      }

      // 반대 타입의 사용자들 가져오기
      final targetType = userType == 'trainer' ? 'trainee' : 'trainer';

      // 모든 프로필 가져온 후 필터링
      final response = await supabase
          .from('profiles')
          .select()
          .eq('user_type', targetType)
          .neq('user_id', currentUserId);

      List<Map<String, dynamic>> cards = [];
      if (response is List) {
        cards = response
            .map((e) => Map<String, dynamic>.from(e))
            .where((profile) {
              final userId = profile['user_id'] as String? ?? '';
              return !swipedUserIds.contains(userId);
            })
            .toList();
      }

      // 거리 계산 및 정렬 (클라이언트에서 처리)
      for (var card in cards) {
        final lat = (card['latitude'] as num?)?.toDouble();
        final lon = (card['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          final distance = Geolocator.distanceBetween(
            currentLatitude,
            currentLongitude,
            lat,
            lon,
          );
          card['distance_meters'] = distance;
        }
      }

      // 거리 순으로 정렬
      cards.sort((a, b) {
        final aDistance = (a['distance_meters'] as num?)?.toDouble() ?? double.infinity;
        final bDistance = (b['distance_meters'] as num?)?.toDouble() ?? double.infinity;
        return aDistance.compareTo(bDistance);
      });

      return cards;
    } catch (e) {
      print('Fallback 카드 가져오기 실패: $e');
      return [];
    }
  }

  /// 좋아요를 보낸 프로필 목록 가져오기 (거리 정보 포함)
  /// [currentUserId]: 현재 로그인한 유저의 ID
  static Future<List<Map<String, dynamic>>> getLikedProfiles(String currentUserId) async {
    print('========================================');
    print('getLikedProfiles 시작');
    print('  - currentUserId: $currentUserId');
    
    try {
      // 현재 인증된 사용자 확인
      final currentAuthUser = supabase.auth.currentUser;
      print('현재 인증된 사용자:');
      print('  - ID: ${currentAuthUser?.id}');
      print('  - Email: ${currentAuthUser?.email}');
      
      if (currentAuthUser == null) {
        print('ERROR: 인증된 사용자가 없습니다!');
        return [];
      }
      
      // currentUserId와 auth.uid()가 일치하는지 확인
      if (currentUserId != currentAuthUser.id) {
        print('⚠ 경고: currentUserId($currentUserId)와 auth.uid()(${currentAuthUser.id})가 일치하지 않습니다!');
        print('  -> auth.uid()를 사용합니다.');
      }
      
      // 먼저 matches 테이블에서 모든 레코드 확인 (디버깅용)
      print('matches 테이블 전체 조회 (디버깅)...');
      try {
        final allMatches = await supabase
            .from('matches')
            .select();
        print('  전체 matches 레코드 수: ${allMatches.length}');
        if (allMatches.isNotEmpty) {
          print('  첫 번째 레코드: ${allMatches[0]}');
        }
      } catch (e) {
        print('  전체 matches 조회 실패: $e');
      }
      
      // 현재 사용자의 모든 matches 조회
      print('현재 사용자의 matches 조회...');
      try {
        final userMatches = await supabase
            .from('matches')
            .select()
            .eq('user_id', currentAuthUser.id);
        print('  현재 사용자의 matches 레코드 수: ${userMatches.length}');
        if (userMatches.isNotEmpty) {
          print('  matches 상세:');
          for (var match in userMatches) {
            print('    - user_id: ${match['user_id']}, swiped_user_id: ${match['swiped_user_id']}, is_match: ${match['is_match']}');
          }
        }
      } catch (e) {
        print('  현재 사용자의 matches 조회 실패: $e');
        print('  이것은 RLS 정책 문제일 수 있습니다!');
      }
      
      // 좋아요를 보낸 사용자 ID 목록 가져오기 (is_match = true)
      print('좋아요한 사용자 ID 조회 (is_match = true)...');
      final matchesResponse = await supabase
          .from('matches')
          .select('swiped_user_id')
          .eq('user_id', currentAuthUser.id)
          .eq('is_match', true);

      print('matchesResponse 타입: ${matchesResponse.runtimeType}');
      print('matchesResponse 내용: $matchesResponse');

      if (matchesResponse is! List) {
        print('ERROR: matchesResponse가 List가 아닙니다!');
        print('  타입: ${matchesResponse.runtimeType}');
        return [];
      }

      final likedUserIds = matchesResponse
          .map((e) {
            final map = Map<String, dynamic>.from(e);
            return map['swiped_user_id'] as String? ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toList();

      print('좋아요한 사용자 ID 목록: $likedUserIds (총 ${likedUserIds.length}개)');

      if (likedUserIds.isEmpty) {
        print('좋아요한 사용자가 없음');
        print('========================================');
        return [];
      }

      // 현재 사용자의 위치 가져오기 (거리 계산용)
      double? currentLat;
      double? currentLon;
      try {
        final currentUserProfile = await getCurrentUserProfile();
        if (currentUserProfile != null) {
          currentLat = (currentUserProfile['latitude'] as num?)?.toDouble();
          currentLon = (currentUserProfile['longitude'] as num?)?.toDouble();
          print('현재 사용자 위치: lat=$currentLat, lon=$currentLon');
        }
      } catch (e) {
        print('현재 사용자 위치 가져오기 실패: $e');
      }

      // 좋아요한 사용자들의 프로필 가져오기
      print('프로필 가져오기 시작...');
      List<Map<String, dynamic>> profiles = [];
      
      for (final userId in likedUserIds) {
        try {
          print('  프로필 가져오기 시도 - userId: $userId');
          final profileResponse = await supabase
              .from('profiles')
              .select()
              .eq('user_id', userId)
              .maybeSingle();
          
          if (profileResponse != null) {
            print('  ✓ 프로필 찾음 - userId: $userId, name: ${profileResponse['name']}');
            final profile = Map<String, dynamic>.from(profileResponse);
            
            // 거리 계산 (현재 사용자 위치가 있는 경우)
            if (currentLat != null && currentLon != null) {
              final profileLat = (profile['latitude'] as num?)?.toDouble();
              final profileLon = (profile['longitude'] as num?)?.toDouble();
              if (profileLat != null && profileLon != null) {
                final distance = Geolocator.distanceBetween(
                  currentLat,
                  currentLon,
                  profileLat,
                  profileLon,
                );
                profile['distance_meters'] = distance;
                print('  거리: ${distance.toStringAsFixed(0)}m');
              }
            }
            
            profiles.add(profile);
          } else {
            print('  ✗ 프로필 없음 - userId: $userId');
          }
        } catch (e) {
          print('  ✗ 프로필 가져오기 실패 (userId: $userId): $e');
        }
      }

      print('최종 프로필 개수: ${profiles.length}');
      print('========================================');
      return profiles;
    } catch (e, stackTrace) {
      print('========================================');
      print('✗ getLikedProfiles 실패');
      print('  - Error: $e');
      print('  - Error Type: ${e.runtimeType}');
      print('  - Error toString: ${e.toString()}');
      
      // RLS 정책 관련 에러 확인
      if (e.toString().contains('PostgrestException') || 
          e.toString().contains('RLS') ||
          e.toString().contains('policy') ||
          e.toString().contains('permission denied')) {
        print('  - 이것은 RLS 정책 오류일 수 있습니다!');
        print('  - matches 테이블의 SELECT 정책을 확인하세요.');
      }
      
      print('  - StackTrace: $stackTrace');
      print('========================================');
      return [];
    }
  }

  /// 사용자 약관 동의 여부 확인
  /// [agreementType]: 'trainer_terms' 또는 'trainee_waiver'
  /// [version]: 약관 버전 (예: 'v1.0')
  static Future<bool> hasUserAgreed({
    required String agreementType,
    String? version,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      var query = supabase
          .from('user_agreements')
          .select()
          .eq('user_id', user.id)
          .eq('agreement_type', agreementType);

      if (version != null) {
        query = query.eq('version', version);
      }

      final response = await query;
      
      if (response is List) {
        return response.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      print('Failed to check user agreement: $e');
      return false;
    }
  }

  /// 사용자 약관 동의 저장
  /// [agreementType]: 'trainer_terms' 또는 'trainee_waiver'
  /// [version]: 약관 버전 (예: 'v1.0')
  static Future<void> saveUserAgreement({
    required String agreementType,
    required String version,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await supabase.from('user_agreements').insert({
        'user_id': user.id,
        'agreement_type': agreementType,
        'version': version,
        'agreed_at': DateTime.now().toIso8601String(),
      });

      print('User agreement saved: $agreementType, version: $version');
    } catch (e) {
      print('Failed to save user agreement: $e');
      rethrow;
    }
  }
}
