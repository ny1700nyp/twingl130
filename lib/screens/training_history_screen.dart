import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'chat_screen.dart';
import '../utils/time_utils.dart';

class TrainingHistoryScreen extends StatefulWidget {
  final String otherUserId;
  final Map<String, dynamic>? otherProfile;

  const TrainingHistoryScreen({
    super.key,
    required this.otherUserId,
    this.otherProfile,
  });

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  ImageProvider? _imageProviderFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(path.split(',').last));
      } catch (_) {
        return null;
      }
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      // Local file paths not supported here yet (web-safe).
      return null;
    }
    return null;
  }

  String _normalizedStatus(Map<String, dynamic> c) {
    return (c['status']?.toString() ?? '').trim().toLowerCase();
  }

  DateTime? _latestMessageAtLocal(Map<String, dynamic> c) {
    final latest = c['latest_message'];
    if (latest is Map) {
      return TimeUtils.tryParseIsoToLocal((latest['created_at'] as String?) ?? '');
    }
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
    final m = RegExp(r'^(declined|declided)\s*:?\s*', caseSensitive: false).firstMatch(text);
    if (m == null) return text;
    return text.substring(m.end).trim();
  }

  String _previewText(Map<String, dynamic>? latest) {
    if (latest == null) return '';
    final type = (latest['type'] as String?) ?? 'text';
    final text = (latest['content'] as String?) ?? (latest['message_text'] as String?) ?? '';
    if (type == 'request') return 'Request';
    if (type == 'system') {
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

  Widget _roleIconBadge(BuildContext context, {required bool isTutor}) {
    const tutorGold = Color(0xFFF59E0B);
    const studentBlue = Color(0xFF4285F4); // Google blue
    final bg = isTutor ? tutorGold : studentBlue;
    final label = isTutor ? 'T' : 'S';

    return Positioned(
      right: -1,
      top: -1,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
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

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // 현재 사용자 프로필 가져오기 (user_type 확인용)
      final currentProfile = await SupabaseService.getCurrentUserProfile();
      final userType = currentProfile?['user_type'] as String?;
      
      if (userType == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 사용자 타입에 따라 conversations 가져오기
      final allConversations = await SupabaseService.getUserConversations(currentUser.id, userType);
      
      // 특정 사용자와의 대화만 필터링
      final filteredConversations = allConversations.where((conv) {
        final trainerId = conv['trainer_id'] as String?;
        final traineeId = conv['trainee_id'] as String?;
        return trainerId == widget.otherUserId || traineeId == widget.otherUserId;
      }).toList();
      
      // 각 conversation의 최신 메시지, request 메시지, 읽지 않은 메시지 수 가져오기
      final conversationsWithDetails = await Future.wait(
        filteredConversations.map((conv) async {
          final latestMessage = await SupabaseService.getLatestMessage(conv['id'] as String);
          final requestMessage = await SupabaseService.getRequestMessage(conv['id'] as String);
          final unreadCount = await SupabaseService.getUnreadMessageCount(
            conv['id'] as String,
            currentUser.id,
          );
          
          // 현재 사용자가 요청을 보낸 사람인지 확인
          final isRequester = (conv['trainee_id'] as String) == currentUser.id;
          
          return {
            ...conv,
            'latest_message': latestMessage,
            'request_message': requestMessage,
            'unread_count': unreadCount,
            'is_requester': isRequester,
          };
        }),
      );

      // 정렬: 읽지 않은 메시지가 있는 것 우선, 그 다음 최신 메시지 시간순
      conversationsWithDetails.sort((a, b) {
        final aUnread = a['unread_count'] as int;
        final bUnread = b['unread_count'] as int;
        
        if (aUnread > 0 && bUnread == 0) return -1;
        if (aUnread == 0 && bUnread > 0) return 1;
        
        final aMessage = a['latest_message'] as Map<String, dynamic>?;
        final bMessage = b['latest_message'] as Map<String, dynamic>?;
        
        if (aMessage == null && bMessage == null) return 0;
        if (aMessage == null) return 1;
        if (bMessage == null) return -1;
        
        final aTime =
            TimeUtils.tryParseIsoToLocal(aMessage['created_at'] as String?) ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            TimeUtils.tryParseIsoToLocal(bMessage['created_at'] as String?) ??
                DateTime.fromMillisecondsSinceEpoch(0);
        
        return bTime.compareTo(aTime);
      });

      setState(() {
        _conversations = conversationsWithDetails;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load conversations: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.otherProfile?['name'] as String? ?? 'Unknown';
    final avatarPath = widget.otherProfile?['main_photo_path'] as String?;
    final avatar = _imageProviderFromPath(avatarPath);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat history with $otherName'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No chat history yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final latestMessage = conversation['latest_message'] as Map<String, dynamic>?;
                      final unreadCount = conversation['unread_count'] as int;
                      final status = _normalizedStatus(conversation);
                      final isRequester = conversation['is_requester'] as bool? ?? false;
                      final isDeclined = status == 'declined';
                      final rightTime = _formatRightCornerTime(conversation);
                      final isOtherTutor = isRequester; // if I requested, other is tutor

                      return ListTile(
                        tileColor: isDeclined ? Colors.red.withAlpha(18) : null,
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundImage: avatar,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: avatar == null ? const Icon(Icons.person) : null,
                            ),
                            _roleIconBadge(context, isTutor: isOtherTutor),
                          ],
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
                            _statusChip(context, status),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _previewText(latestMessage),
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
                        onTap: () {
                          final currentUser = Supabase.instance.client.auth.currentUser;
                          if (currentUser == null) return;
                          
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                conversationId: conversation['id'] as String,
                                otherUserId: widget.otherUserId,
                                otherProfile: widget.otherProfile,
                              ),
                            ),
                          ).then((_) => _loadConversations());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
