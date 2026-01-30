import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

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
        
        final aTime = DateTime.parse(aMessage['created_at'] as String);
        final bTime = DateTime.parse(bMessage['created_at'] as String);
        
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

  String _formatMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);
    
    if (messageDate == today) {
      final hour = messageTime.hour.toString().padLeft(2, '0');
      final minute = messageTime.minute.toString().padLeft(2, '0');
      return 'Today $hour:$minute';
    } else if (messageDate == yesterday) {
      final hour = messageTime.hour.toString().padLeft(2, '0');
      final minute = messageTime.minute.toString().padLeft(2, '0');
      return 'Yesterday $hour:$minute';
    } else {
      final month = messageTime.month.toString().padLeft(2, '0');
      final day = messageTime.day.toString().padLeft(2, '0');
      final hour = messageTime.hour.toString().padLeft(2, '0');
      final minute = messageTime.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    }
  }

  Widget _buildStatusChip(String status, BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    switch (status) {
      case 'pending':
        return Chip(
          label: const Text('Pending'),
          backgroundColor: AppTheme.secondaryGold.withOpacity(0.2),
          labelStyle: const TextStyle(
            color: AppTheme.secondaryGold,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: AppTheme.secondaryGold.withOpacity(0.2),
          ),
        );
      case 'accepted':
        return Chip(
          label: const Text('Accepted'),
          backgroundColor: AppTheme.successGreen.withOpacity(0.2),
          labelStyle: const TextStyle(
            color: AppTheme.successGreen,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: AppTheme.successGreen.withOpacity(0.2),
          ),
        );
      case 'declined':
        return Chip(
          label: const Text('Declined'),
          backgroundColor: Colors.red.withOpacity(0.2),
          labelStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: Colors.red.withOpacity(0.2),
          ),
        );
      default:
        return Chip(
          label: Text(status),
          backgroundColor: theme.surfaceVariant,
          labelStyle: TextStyle(
            color: theme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: theme.surfaceVariant,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = widget.otherProfile?['name'] as String? ?? 'Unknown';
    
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
                      final requestMessage = conversation['request_message'] as Map<String, dynamic>?;
                      final unreadCount = conversation['unread_count'] as int;
                      final status = conversation['status'] as String? ?? 'pending';
                      final isRequester = conversation['is_requester'] as bool? ?? false;
                      
                      // Extract talent/skill from request message metadata
                      String? talent;
                      if (requestMessage != null) {
                        final metadata = requestMessage['metadata'] as Map<String, dynamic>?;
                        talent = metadata?['skill'] as String?;
                      }
                      
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.school,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: talent != null && talent.isNotEmpty
                            ? Row(
                                children: [
                                  Icon(
                                    isRequester ? Icons.send : Icons.inbox,
                                    size: 14,
                                    color: isRequester ? const Color(0xFFF59E0B) : Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      isRequester 
                                          ? 'Requested: $talent'
                                          : 'Received: $talent',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isRequester ? const Color(0xFFF59E0B) : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text('Training Request'),
                        subtitle: latestMessage != null
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      latestMessage['content'] as String? ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatMessageTime(
                                      DateTime.parse(latestMessage['created_at'] as String),
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Status: $status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: status == 'pending'
                                      ? AppTheme.secondaryGold
                                      : status == 'accepted'
                                          ? AppTheme.successGreen
                                          : status == 'declined'
                                              ? Colors.red
                                              : Colors.grey,
                                ),
                              ),
                        trailing: _buildStatusChip(status, context),
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
