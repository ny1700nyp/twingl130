import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/quote_service.dart';
import '../services/supabase_service.dart';
import '../utils/time_utils.dart';
import '../widgets/avatar_with_type_badge.dart';
import '../widgets/spark_card.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int? resetToken;
  final bool showBackButton;

  const DashboardScreen({super.key, this.resetToken, this.showBackButton = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _lastResetToken;
  final Map<String, ImageProvider> _avatarProviderCache = {};
  Future<DailyQuote?>? _dailyQuoteFuture;

  RealtimeChannel? _conversationsTrainerChannel;
  RealtimeChannel? _conversationsTraineeChannel;
  final Map<String, RealtimeChannel> _messageChannelsByConversationId = {};
  VoidCallback? _chatCacheListener;

  @override
  void initState() {
    super.initState();
    _lastResetToken = widget.resetToken;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      SupabaseService.getChatConversationsCached(user.id);
      _subscribeToConversationsRealtime(user.id);
      _dailyQuoteFuture = QuoteService.getDailyQuote(userId: user.id);
    }

    // When the dashboard list changes, keep per-conversation message subscriptions in sync.
    _chatCacheListener = () {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;
      final list = SupabaseService.chatConversationsCache.value;
      if (list == null) return;
      _syncMessageRealtimeSubscriptions(me.id, list);
    };
    SupabaseService.chatConversationsCache.addListener(_chatCacheListener!);
  }

  @override
  void dispose() {
    if (_chatCacheListener != null) {
      SupabaseService.chatConversationsCache.removeListener(_chatCacheListener!);
    }
    _conversationsTrainerChannel?.unsubscribe();
    _conversationsTraineeChannel?.unsubscribe();
    for (final ch in _messageChannelsByConversationId.values) {
      ch.unsubscribe();
    }
    _messageChannelsByConversationId.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetToken != null && widget.resetToken != _lastResetToken) {
      _lastResetToken = widget.resetToken;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        SupabaseService.getChatConversationsCached(user.id, forceRefresh: true);
      }
    }
  }

  void _subscribeToConversationsRealtime(String userId) {
    final client = Supabase.instance.client;

    // New/updated conversations where I'm the trainer.
    _conversationsTrainerChannel?.unsubscribe();
    _conversationsTrainerChannel = client.channel('dash:conversations:trainer:$userId');
    _conversationsTrainerChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trainer_id',
            value: userId,
          ),
          callback: (_) => SupabaseService.refreshChatConversationsIfChanged(userId),
        )
        .subscribe();

    // New/updated conversations where I'm the trainee.
    _conversationsTraineeChannel?.unsubscribe();
    _conversationsTraineeChannel = client.channel('dash:conversations:trainee:$userId');
    _conversationsTraineeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trainee_id',
            value: userId,
          ),
          callback: (_) => SupabaseService.refreshChatConversationsIfChanged(userId),
        )
        .subscribe();
  }

  void _syncMessageRealtimeSubscriptions(String userId, List<Map<String, dynamic>> conversations) {
    final wanted = <String>{};
    for (final c in conversations) {
      final id = c['id']?.toString();
      if (id != null && id.isNotEmpty) wanted.add(id);
    }

    // Remove stale.
    final existingIds = _messageChannelsByConversationId.keys.toList(growable: false);
    for (final id in existingIds) {
      if (!wanted.contains(id)) {
        _messageChannelsByConversationId[id]?.unsubscribe();
        _messageChannelsByConversationId.remove(id);
      }
    }

    // Add new.
    final client = Supabase.instance.client;
    for (final conversationId in wanted) {
      if (_messageChannelsByConversationId.containsKey(conversationId)) continue;
      final ch = client.channel('dash:messages:$conversationId');
      ch.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: conversationId,
        ),
        callback: (payload) {
          // Keep per-conversation cache warm for instant open, and refresh dashboard metadata (latest/unread).
          final row = payload.newRecord;
          if (row.isNotEmpty) {
            SupabaseService.upsertChatMessageIntoCache(
              userId: userId,
              conversationId: conversationId,
              message: Map<String, dynamic>.from(row),
            );
          }
          SupabaseService.refreshChatConversationsIfChanged(userId);
        },
      ).subscribe();
      _messageChannelsByConversationId[conversationId] = ch;
    }
  }

  ImageProvider? _imageProviderForAvatar(String conversationId, String? path) {
    if (path == null || path.isEmpty) return null;
    final cached = _avatarProviderCache[conversationId];
    if (cached != null) return cached;

    ImageProvider? provider;
    if (path.startsWith('data:image')) {
      try {
        provider = MemoryImage(base64Decode(path.split(',').last));
      } catch (_) {}
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      provider = NetworkImage(path);
    } else if (!kIsWeb) {
      provider = null;
    }

    if (provider != null) {
      _avatarProviderCache[conversationId] = provider;
    }
    return provider;
  }

  String _normalizedStatus(Map<String, dynamic> c) {
    return (c['status']?.toString() ?? '').trim().toLowerCase();
  }

  DateTime? _latestMessageAtLocal(Map<String, dynamic> c) {
    final latest = c['latest_message'];
    if (latest is Map) {
      return TimeUtils.tryParseIsoToLocal((latest['created_at'] as String?) ?? '');
    }
    // fallback to conversation updated_at
    return TimeUtils.tryParseIsoToLocal((c['updated_at'] as String?) ?? '');
  }

  String _formatRightCornerTime(Map<String, dynamic> c) {
    final dt = _latestMessageAtLocal(c);
    if (dt == null) return '';
    final now = TimeUtils.nowLocal();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return 'Today';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  String _stripDeclinedPrefix(String s) {
    final text = s.trim();
    // Handle common variants/misspellings: "Declined:" / "declined :" / "Declided:"
    final m = RegExp(r'^(declined|declided)\s*:?\s*', caseSensitive: false).firstMatch(text);
    if (m == null) return text;
    return text.substring(m.end).trim();
  }

  Widget _statusChip(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'accepted' || s.isEmpty) return const SizedBox.shrink();

    late final Color bg;
    late final Color fg;
    late final String label;

    if (s == 'declined') {
      bg = Colors.red.withAlpha(28);
      fg = Colors.red.shade700;
      label = 'Declined';
    } else if (s == 'pending') {
      bg = Colors.orange.withAlpha(30);
      fg = Colors.orange.shade800;
      label = 'Pending';
    } else {
      bg = Colors.grey.withAlpha(28);
      fg = Colors.grey.shade700;
      label = s;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  String _previewText(Map<String, dynamic>? latest) {
    if (latest == null) return '';
    final type = (latest['type'] as String?) ?? 'text';
    final text = (latest['content'] as String?) ?? (latest['message_text'] as String?) ?? '';
    if (type == 'request') return 'Request';
    if (type == 'system') {
      // If it's a decline reason, remove "Declined:" prefix in preview.
      final metadata = latest['metadata'];
      String? kind;
      try {
        if (metadata is Map) {
          kind = (metadata['kind'] as String?)?.toString();
        } else if (metadata is String && metadata.isNotEmpty) {
          final decoded = jsonDecode(metadata);
          if (decoded is Map) kind = (decoded['kind'] as String?)?.toString();
        }
      } catch (_) {}
      if (kind == 'decline_reason') return _stripDeclinedPrefix(text);
      if (RegExp(r'^(declined|declided)\s*:?', caseSensitive: false).hasMatch(text.trim())) {
        return _stripDeclinedPrefix(text);
      }
      return text;
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text('Chat'),
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>?>(
        valueListenable: SupabaseService.chatConversationsCache,
        builder: (context, value, _) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            return const Center(child: Text('Please log in.'));
          }
          if (value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = value;

          Widget quoteCard = Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: FutureBuilder<DailyQuote?>(
              future: _dailyQuoteFuture,
              builder: (context, snap) {
                final q = snap.data;
                if (q == null) return const SizedBox.shrink();
                return SparkCard(quote: q.quote, author: q.author);
              },
            ),
          );

          return RefreshIndicator(
            onRefresh: () => SupabaseService.getChatConversationsCached(user.id, forceRefresh: true),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: quoteCard),
                if (list.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text('No conversations yet.')),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final c = list[i];
                final conversationId = c['id']?.toString() ?? '';
                if (conversationId.isEmpty) return const SizedBox.shrink();

                final otherProfile = c['other_profile'] as Map<String, dynamic>?;
                final otherName = (otherProfile?['name'] as String?) ?? 'Unknown';
                final avatarPath = otherProfile?['main_photo_path'] as String?;
                final avatar = _imageProviderForAvatar(conversationId, avatarPath);

                final unreadCount = (c['unread_count'] as num?)?.toInt() ?? 0;
                final latest = c['latest_message'] as Map<String, dynamic>?;
                final status = _normalizedStatus(c);
                final isDeclined = status == 'declined';
                final rightTime = _formatRightCornerTime(c);
                final otherUserId = (c['other_user_id'] as String?) ??
                    (otherProfile?['user_id'] as String?) ??
                    '';

                return ListTile(
                  key: ValueKey(conversationId),
                  tileColor: isDeclined ? Colors.red.withAlpha(18) : null,
                  leading: AvatarWithTypeBadge(
                    radius: 22,
                    backgroundImage: avatar,
                    userType: otherProfile?['user_type'] as String?,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      _statusChip(status),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _previewText(latest),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDeclined ? Colors.red.shade700 : null,
                            fontWeight: isDeclined ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                      if (rightTime.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          rightTime,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ],
                  ),
                  onTap: otherUserId.isEmpty
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conversationId,
                                otherUserId: otherUserId,
                                otherProfile: otherProfile,
                              ),
                            ),
                          );
                          // Background refresh when returning.
                          SupabaseService.refreshChatConversationsIfChanged(user.id);
                        },
                );
                      },
                      childCount: list.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

