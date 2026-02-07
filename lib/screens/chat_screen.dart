import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance_formatter.dart';
import '../utils/time_utils.dart';
import '../widgets/schedule_message_bubble.dart';
import 'profile_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final Map<String, dynamic>? otherProfile;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    this.otherProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _inputFocusNode = FocusNode();
  late final AutoScrollController _scrollController = AutoScrollController();

  Map<String, dynamic>? _conversation;
  bool _isSending = false;
  /// ID of the first unread message from the other person (before marking read).
  String? _firstUnreadMessageId;
  /// Index in filtered list (oldest-first order) for first unread message.
  int? _firstUnreadMessageIndex;
  bool _paymentNoticeExpanded = false;
  bool _isLoadingMore = false;
  bool _hasNoMoreOlder = false;
  bool _initialScrollApplied = false;

  DateTime? _lastLoadMoreCheck;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationChannel;

  @override
  void initState() {
    super.initState();
    SupabaseService.currentlyViewingConversationId = widget.conversationId;
    _loadConversationAndMessages();
    _subscribeToMessagesRealtime();
    _subscribeToConversationRealtime();
  }

  @override
  void dispose() {
    if (SupabaseService.currentlyViewingConversationId == widget.conversationId) {
      SupabaseService.currentlyViewingConversationId = null;
    }
    _messagesChannel?.unsubscribe();
    _conversationChannel?.unsubscribe();
    _controller.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationAndMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Hydrate from disk for immediate display, then always fetch latest from server
    // so messages received while app was in background are shown.
    await SupabaseService.hydrateChatMessagesFromDisk(user.id, widget.conversationId);
    final fresh = await SupabaseService.getChatMessagesCached(
      user.id,
      widget.conversationId,
      forceRefresh: true,
      limit: 200,
    );

    if (mounted) {
      setState(() {
        _hasNoMoreOlder = fresh.length < 200;
      });
    }

    // Conversation state
    final conv = await SupabaseService.getConversation(widget.conversationId);
    if (!mounted) return;

    // Find oldest unread message from other (before marking read)
    final raw = SupabaseService.chatMessagesCacheForConversation(widget.conversationId).value ?? [];
    final filtered = raw.where((m) => !_shouldHideSystemMessage(m)).toList();
    String? firstUnreadId;
    int? firstUnreadIndex;
    for (var i = 0; i < filtered.length; i++) {
      final m = filtered[i];
      final senderId = m['sender_id']?.toString();
      final isRead = m['is_read'];
      if (senderId != null && senderId != user.id) {
        if (isRead != true) {
          firstUnreadId = m['id']?.toString();
          firstUnreadIndex = i;
          break;
        }
      }
    }
    if (kDebugMode) {
      debugPrint('[chat] _loadConversationAndMessages: filteredCount=${filtered.length} '
          'firstUnreadId=$firstUnreadId firstUnreadIndex=$firstUnreadIndex hasUnread=${firstUnreadId != null}');
    }

    setState(() {
      _conversation = conv;
      _firstUnreadMessageId = firstUnreadId;
      _firstUnreadMessageIndex = firstUnreadIndex;
    });

    // Mark read
    await SupabaseService.markMessagesAsRead(widget.conversationId, user.id);

    _scrollToInitialPosition();
  }

  void _subscribeToMessagesRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final client = Supabase.instance.client;
    _messagesChannel = client.channel('messages:${widget.conversationId}');
    _messagesChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) async {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return;
            final msg = Map<String, dynamic>.from(newRow);
            SupabaseService.upsertChatMessageIntoCache(
              userId: user.id,
              conversationId: widget.conversationId,
              message: msg,
            );

            // If we receive an "accepted" system message, refresh conversation status
            // (helps even if conversations realtime isn't working).
            try {
              final metadata = msg['metadata'];
              String? kind;
              if (metadata is Map) {
                kind = (metadata['kind'] as String?)?.toString();
              } else if (metadata is String && metadata.isNotEmpty) {
                // best-effort parse
                final decoded = jsonDecode(metadata);
                if (decoded is Map) kind = (decoded['kind'] as String?)?.toString();
              }
              if (kind == 'request_accepted' && _conversationStatus() != 'accepted') {
                if (kDebugMode) debugPrint('[chat] got request_accepted msg â†’ refresh conversation');
                final conv = await SupabaseService.getConversation(widget.conversationId);
                if (mounted && conv != null) setState(() => _conversation = conv);
              }
            } catch (_) {}

            await SupabaseService.markMessagesAsRead(widget.conversationId, user.id);
            _scrollToBottom();
            // Update dashboard list in background.
            SupabaseService.refreshChatConversationsIfChanged(user.id);
          },
        )
        .subscribe();
  }

  void _subscribeToConversationRealtime() {
    final client = Supabase.instance.client;
    _conversationChannel = client.channel('conversation:${widget.conversationId}');
    _conversationChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return;
            if (!mounted) return;
            // Some realtime payloads may be partial; merge to avoid losing fields (e.g., status).
            setState(() {
              final merged = <String, dynamic>{
                ...(_conversation ?? const <String, dynamic>{}),
                ...Map<String, dynamic>.from(newRow),
              };
              _conversation = merged;
            });
          },
        )
        .subscribe();
  }

  String _conversationStatus() {
    return ((_conversation?['status'] as String?) ?? '').trim().toLowerCase();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // reverse: true → index 0 is bottom (newest)
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  static const double _loadMoreThreshold = 150;
  static const int _loadOlderPageSize = 100;

  Future<void> _loadOlderMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _isLoadingMore || _hasNoMoreOlder) return;

    setState(() => _isLoadingMore = true);
    final isUnreadMode = _firstUnreadMessageIndex != null;

    try {
      final count = await SupabaseService.loadOlderChatMessages(
        user.id,
        widget.conversationId,
        pageSize: _loadOlderPageSize,
      );
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (count < _loadOlderPageSize) _hasNoMoreOlder = true;
          if (isUnreadMode && _firstUnreadMessageIndex != null && count > 0) {
            _firstUnreadMessageIndex = _firstUnreadMessageIndex! + count;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _scrollToInitialPosition() {
    if (kDebugMode) {
      debugPrint('[chat] _scrollToInitialPosition: firstUnreadId=$_firstUnreadMessageId '
          'firstUnreadIndex=$_firstUnreadMessageIndex');
    }
    setState(() => _initialScrollApplied = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final raw = SupabaseService.chatMessagesCacheForConversation(widget.conversationId).value ?? [];
      final filtered = raw.where((m) => !_shouldHideSystemMessage(m)).toList();
      final targetIndex = (_firstUnreadMessageId != null && _firstUnreadMessageIndex != null)
          ? (filtered.length - 1 - _firstUnreadMessageIndex!)
          : 0;
      if (kDebugMode) debugPrint('[chat] _scrollToInitialPosition: targetIndex=$targetIndex (reverse list)');
      _scrollController.scrollToIndex(
        targetIndex,
        preferPosition: AutoScrollPosition.middle,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  bool _isSystem(Map<String, dynamic> m) => (m['type'] as String?) == 'system';

  Widget _buildPaymentNotice() {
    const quoteGradient = [AppTheme.twinglMint, AppTheme.twinglPurple];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: quoteGradient.first.withAlpha(40),
        child: InkWell(
          onTap: () => setState(() => _paymentNoticeExpanded = !_paymentNoticeExpanded),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: quoteGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: quoteGradient.first.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'How do I pay for lessons?',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha(250),
                          ),
                        ),
                      ),
                      Icon(
                        _paymentNoticeExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white.withAlpha(250),
                        size: 24,
                      ),
                    ],
                  ),
                ),
                if (_paymentNoticeExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildPaymentGuideBody(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingNotice() {
    const pendingGradient = [AppTheme.secondaryGold, AppTheme.twinglMint];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pendingGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: pendingGradient.first.withAlpha(40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Chat is only available after the other person accepts your first class request. Please wait.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(250),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeclinedNotice() {
    const declinedGradient = [AppTheme.secondaryGold, Color(0xFFDC2626)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: declinedGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: declinedGradient.first.withAlpha(40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your request was declined. Please feel free to send a new request when you\'re ready.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(250),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You might also consider finding another tutor.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(230),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _paymentGuideIconSize = 18.0;

  Widget _buildPaymentGuideBody(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withAlpha(250),
      height: 1.4,
      fontWeight: FontWeight.w500,
    );
    final iconColor = Colors.white.withAlpha(250);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Twingl connects you with neighbors, but we don\'t handle payments directly. '
          'This keeps our service free and puts 100% of the fee in your tutor\'s pocket!',
          style: style,
        ),
        const SizedBox(height: 12),
        Text('Please agree on a method that works for both of you, such as:', style: style),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.smartphone, size: _paymentGuideIconSize, color: iconColor),
            const SizedBox(width: 6),
            Expanded(child: Text('Venmo / Zelle / PayPal', style: style)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.attach_money, size: _paymentGuideIconSize, color: iconColor),
            const SizedBox(width: 6),
            Expanded(child: Text('Cash', style: style)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.coffee, size: _paymentGuideIconSize, color: iconColor),
            const SizedBox(width: 6),
            Expanded(child: Text('Coffee or Meal (for casual sessions)', style: style)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Note: For safety, we recommend paying after meeting in person.',
          style: style,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: _paymentGuideIconSize, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tip: For online lessons, consider paying via PayPal for buyer protection, or use the 50/50 payment method.',
                style: style,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnreadDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Unread',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
        ],
      ),
    );
  }

  bool _shouldHideSystemMessage(Map<String, dynamic> m) {
    if (!_isSystem(m)) return false;
    final text = (m['content'] as String?) ?? (m['message_text'] as String?) ?? '';
    // Hide legacy calendar system messages in the new UX.
    return text.contains('Added') && text.contains('Calendar');
  }

  Future<void> _showProposeLessonSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProposeLessonSheetContent(
        onSend: (data) => Navigator.of(ctx).pop(data),
      ),
    );
    if (result != null) {
      await _sendScheduleProposal(result);
    }
  }

  Future<void> _sendScheduleProposal(Map<String, dynamic> data) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final status = _conversationStatus();
    if (status != 'accepted') return;
    if (_isSending) return;

    setState(() => _isSending = true);

    final lessonDate = data['lessonDate'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final durationMinutes = data['durationMinutes'] as int? ?? 60;

    final clientId =
        '${user.id}:${DateTime.now().microsecondsSinceEpoch}:${Random().nextInt(0x7fffffff)}';
    final metadata = <String, dynamic>{
      'client_id': clientId,
      'type': 'schedule_proposal',
      'lessonDate': lessonDate,
      'location': location,
      'durationMinutes': durationMinutes,
    };

    String displayDate = 'â€”';
    if (lessonDate.isNotEmpty) {
      try {
        displayDate = DateFormat('MMM d (EEE), h:mm a')
            .format(DateTime.parse(lessonDate).toLocal());
      } catch (_) {
        displayDate = lessonDate;
      }
    }
    final messageText =
        'Scheduling: $displayDate${location.isNotEmpty ? ' at $location' : ''}';

    final optimistic = <String, dynamic>{
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'conversation_id': widget.conversationId,
      'sender_id': user.id,
      'content': messageText,
      'message_text': messageText,
      'metadata': metadata,
      'type': 'schedule_proposal',
      'is_read': true,
      'created_at': TimeUtils.nowUtcIso(),
    };
    SupabaseService.upsertChatMessageIntoCache(
      userId: user.id,
      conversationId: widget.conversationId,
      message: optimistic,
    );
    _scrollToBottom();

    try {
      await SupabaseService.sendMessage(
        conversationId: widget.conversationId,
        senderId: user.id,
        messageText: messageText,
        type: 'schedule_proposal',
        metadata: metadata,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send proposal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendMessage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // Chat is enabled only after the training request is accepted.
    final status = _conversationStatus();
    if (kDebugMode) debugPrint('[chat] sendMessage tapped status=$status');
    if (status != 'accepted') return;
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();
    _inputFocusNode.requestFocus();

    // NOTE: On web, bit-shifts beyond 31 bits can overflow to 0 in JS.
    // Keep max <= 2^31-1 to avoid RangeError in Random.nextInt().
    final clientId =
        '${user.id}:${DateTime.now().microsecondsSinceEpoch}:${Random().nextInt(0x7fffffff)}';
    final metadata = <String, dynamic>{'client_id': clientId};

    // Optimistic cache insert
    final optimistic = <String, dynamic>{
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'conversation_id': widget.conversationId,
      'sender_id': user.id,
      // DB uses `content`; keep `message_text` for backward-compat in UI.
      'content': text,
      'message_text': text,
      'metadata': metadata,
      'type': 'text',
      'is_read': true,
      'created_at': TimeUtils.nowUtcIso(),
    };
    SupabaseService.upsertChatMessageIntoCache(
      userId: user.id,
      conversationId: widget.conversationId,
      message: optimistic,
    );
    _scrollToBottom();

    try {
      await SupabaseService.sendMessage(
        conversationId: widget.conversationId,
        senderId: user.id,
        messageText: text,
        type: 'text',
        metadata: metadata,
      );
      if (kDebugMode) debugPrint('[chat] sendMessage DB insert OK');
    } catch (e) {
      if (kDebugMode) debugPrint('[chat] sendMessage DB insert FAILED: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _acceptRequest() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      final before = _conversationStatus();
      if (kDebugMode) debugPrint('[chat] accept tapped before=$before');
      await SupabaseService.acceptTrainingRequest(widget.conversationId);

      // Enable chat immediately locally.
      if (mounted) {
        setState(() {
          _conversation = <String, dynamic>{
            ...(_conversation ?? const <String, dynamic>{}),
            'status': 'accepted',
            'updated_at': TimeUtils.nowUtcIso(),
          };
        });
      }

      // Notify the other user that chat is now available.
      await SupabaseService.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.id,
        messageText: 'Accepted. You can chat now.',
        type: 'system',
        metadata: const <String, dynamic>{'kind': 'request_accepted'},
      );
      await SupabaseService.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.id,
        messageText: 'Please discuss your availability, preferred location, and rates to kick things off.',
        type: 'system',
        metadata: const <String, dynamic>{'kind': 'schedule_prompt'},
      );

      final conv = await SupabaseService.getConversation(widget.conversationId);
      if (!mounted) return;
      setState(() => _conversation = conv ?? _conversation);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    }
  }

  Future<void> _declineRequest() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final parentMessenger = ScaffoldMessenger.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Decline reason', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Why are you declining?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        Navigator.of(context).pop(text);
                      },
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (reason == null) return;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return;

    try {
      await SupabaseService.declineTrainingRequest(widget.conversationId);
      await SupabaseService.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.id,
        messageText: 'Declined: $trimmed',
        type: 'system',
        metadata: <String, dynamic>{
          'kind': 'decline_reason',
          'reason': trimmed,
        },
      );
      final conv = await SupabaseService.getConversation(widget.conversationId);
      if (!mounted) return;
      setState(() => _conversation = conv);
      parentMessenger.showSnackBar(const SnackBar(content: Text('Declined')));
    } catch (e) {
      if (!mounted) return;
      parentMessenger.showSnackBar(SnackBar(content: Text('Failed to decline: $e')));
    }
  }

  Widget _buildRequestActionArea() {
    final conv = _conversation;
    if (conv == null) return const SizedBox.shrink();
    final status = _conversationStatus();
    if (status != 'pending') return const SizedBox.shrink();

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return const SizedBox.shrink();
    final trainerId = conv['trainer_id'] as String?;
    final isTrainer = trainerId == currentUser.id;
    if (!isTrainer) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: _declineRequest, child: const Text('Decline')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(onPressed: _acceptRequest, child: const Text('Accept')),
          ),
        ],
      ),
    );
  }

  // Scheduling / calendar integration removed.

  DateTime? _messageCreatedAtLocal(Map<String, dynamic> m) {
    final raw = m['created_at']?.toString() ?? '';
    final dt = DateTime.tryParse(raw);
    return dt?.toLocal();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String? _timestampLabel({
    required DateTime? prev,
    required DateTime? curr,
  }) {
    if (curr == null) return null;
    if (prev != null && !_isSameDay(prev, curr)) {
      // Date changed since previous message â†’ show date.
      return DateFormat('yyyy-MM-dd').format(curr);
    }
    // Same day: show time only if 1+ minute since previous message
    if (prev != null) {
      final diffSec = curr.difference(prev).inSeconds.abs();
      if (diffSec < 60) return null;
    }
    return DateFormat('HH:mm').format(curr);
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> m, {
    required Map<String, dynamic>? prevMessage,
  }) {
    if (_shouldHideSystemMessage(m)) return const SizedBox.shrink();

    final currentUser = Supabase.instance.client.auth.currentUser;
    final senderId = m['sender_id'] as String?;
    final isMe = currentUser != null && senderId == currentUser.id;

    final text = (m['content'] as String?) ?? (m['message_text'] as String?) ?? '';
    final type = (m['type'] as String?) ?? 'text';

    // Schedule proposal message: render custom bubble with Add to Calendar
    final meta = m['metadata'];
    final metaMap = meta is Map<String, dynamic>
        ? meta
        : (meta is Map ? Map<String, dynamic>.from(meta) : null);
    final metaType = metaMap?['type'] as String?;
    if (type == 'schedule_proposal' ||
        (type == 'text' && metaType == 'schedule_proposal')) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: ScheduleMessageBubble(
              metadata: metaMap ?? const {},
              senderDisplayName: isMe ? null : (widget.otherProfile?['name'] as String?),
              otherPartyNameForCalendar: widget.otherProfile?['name'] as String?,
              isMe: isMe,
              timestamp: _timestampLabel(
                prev: prevMessage == null ? null : _messageCreatedAtLocal(prevMessage),
                curr: _messageCreatedAtLocal(m),
              ),
            ),
          ),
        ),
      );
    }

    final isSystem = _isSystem(m);
    final ts = _timestampLabel(
      prev: prevMessage == null ? null : _messageCreatedAtLocal(prevMessage),
      curr: _messageCreatedAtLocal(m),
    );
    final metadata = m['metadata'];
    String? kind;
    if (metadata is Map<String, dynamic>) {
      kind = metadata['kind'] as String?;
    } else if (metadata is Map) {
      kind = (metadata['kind'] as dynamic)?.toString();
    }
    final isQuoteStyleSystem =
        isSystem && (kind == 'request_accepted' || kind == 'schedule_prompt');
    const declinedMessageGradient = [AppTheme.secondaryGold, Color(0xFFDC2626)];
    final isDeclineReason = isSystem && kind == 'decline_reason';

    final currentUserId = currentUser?.id;
    final traineeId = _conversation?['trainee_id'] as String?;
    final isRequestSender = currentUserId != null && currentUserId == traineeId;
    final quoteGradient = isDeclineReason
        ? declinedMessageGradient
        : (isQuoteStyleSystem
            ? (isRequestSender
                ? [AppTheme.twinglMint, AppTheme.twinglPurple]
                : [AppTheme.twinglPurple, AppTheme.twinglMint])
            : null);

    final bubbleColor = quoteGradient != null
        ? null
        : isSystem
            ? Colors.grey.shade200
            : isMe
                ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest;
    final align = isSystem ? Alignment.center : (isMe ? Alignment.centerRight : Alignment.centerLeft);

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: isSystem
                    ? MainAxisAlignment.center
                    : (isMe ? MainAxisAlignment.end : MainAxisAlignment.start),
                children: [
                  if (!isSystem && isMe && ts != null) ...[
                    Text(
                      ts,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(quoteGradient != null ? 16 : 14),
                        boxShadow: quoteGradient != null
                            ? [
                                BoxShadow(
                                  color: quoteGradient.first.withAlpha(40),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                        gradient: quoteGradient != null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: quoteGradient,
                              )
                            : null,
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: (quoteGradient != null || isDeclineReason)
                              ? Colors.white.withAlpha(250)
                              : isSystem
                                  ? Colors.grey.shade800
                                  : null,
                          fontWeight: isSystem || quoteGradient != null || isDeclineReason
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  if (!isSystem && !isMe && ts != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      ts,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
              if (type == 'request')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Request', style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sheetAgeRange(int? age, String? createdAt) {
    if (age == null) return '';
    int currentYear = DateTime.now().year;
    int registrationYear = currentYear;
    if (createdAt != null) {
      try {
        registrationYear = DateTime.parse(createdAt).year;
      } catch (_) {}
    }
    int currentAge = age + (currentYear - registrationYear);
    int ageRange = (currentAge ~/ 10) * 10;
    return '${ageRange}s';
  }

  static String _sheetGenderLabel(String? gender) {
    if (gender == null || gender.trim().isEmpty || gender == 'Prefer not to say') return '';
    switch (gender.trim().toLowerCase()) {
      case 'man': return 'Man';
      case 'woman': return 'Woman';
      case 'non-binary': return 'Non-binary';
      default: return gender;
    }
  }

  Future<void> _openOtherProfilePopup() async {
    final otherUserId = widget.otherUserId.trim();
    if (otherUserId.isEmpty) return;

    if (!mounted) return;
    // ì‹œíŠ¸ ë“œëž˜ê·¸ ì‹œ ìž¬ë¹Œë“œë˜ì–´ë„ ë¡œë”©ì´ ë‹¤ì‹œ ëœ¨ì§€ ì•Šë„ë¡, Futureë¥¼ í•œ ë²ˆë§Œ ìƒì„±
    final profileFuture = SupabaseService.getPublicProfile(otherUserId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final h = media.size.height;
        final topPadding = media.padding.top;
        // ì‹œíŠ¸ ìƒë‹¨ì´ ì¸ë””ì¼€ì´í„°/ë…¸ì¹˜ ì•„ëž˜ì— ì˜¤ë„ë¡ ë†’ì´ ì œí•œ (ìŠ¬ë¼ì´ë“œ ë‹¤ìš´ìœ¼ë¡œ ë‹«ê¸° ê°€ëŠ¥)
        final sheetHeight = (h - topPadding - 24).clamp(400.0, h * 0.88);
        final surface = Theme.of(ctx).colorScheme.surface;
        return Padding(
          padding: EdgeInsets.only(top: topPadding + 8, left: 12, right: 12, bottom: 12),
          child: Material(
            color: surface,
            elevation: 10,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: sheetHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.onSurface.withAlpha(80),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future: profileFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Failed to load profile: ${snap.error}'),
                            ),
                          );
                        }
                        final profile = snap.data;
                        if (profile == null) {
                          return const Center(child: Text('Profile not found'));
                        }

                        final p = Map<String, dynamic>.from(profile);
                        final meters = _distanceMetersToOther(p);
                        if (meters != null) {
                          p['distance_meters'] = meters;
                        }

                        final name = p['name'] as String? ?? 'Unknown';
                        final age = p['age'] as int?;
                        final gender = p['gender'] as String?;
                        final distanceStr = meters != null ? formatDistanceMeters(meters) : null;
                        final ageStr = _sheetAgeRange(age, p['created_at'] as String?);
                        final genderStr = _sheetGenderLabel(gender);
                        final subParts = <String>[
                          if (distanceStr != null && distanceStr.isNotEmpty) distanceStr,
                          if (ageStr.isNotEmpty) ageStr,
                          if (genderStr.isNotEmpty) genderStr,
                        ];

                        final conv = _conversation;
                        final currentUser = Supabase.instance.client.auth.currentUser;
                        final traineeId = (conv?['trainee_id'] as String?)?.trim();
                        final iSentRequest = currentUser != null && traineeId != null && currentUser.id == traineeId;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (subParts.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subParts.join('  â€¢  '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ProfileDetailScreen(
                                profile: p,
                                hideAppBar: true,
                                hideActionButtons: true,
                                hideNameAgeGenderInBody: true,
                                currentUserProfile: SupabaseService.currentUserProfileCache.value,
                                onLikeFromPhoto: (currentUser != null && otherUserId.isNotEmpty)
                                    ? () async {
                                        if (iSentRequest) {
                                          await SupabaseService.addFavoriteFromChatToTutorTab(
                                            currentUserId: currentUser.id,
                                            otherUserId: otherUserId,
                                            otherProfile: p,
                                          );
                                        } else {
                                          await SupabaseService.addFavoriteFromChatToStudentTab(
                                            currentUserId: currentUser.id,
                                            otherUserId: otherUserId,
                                            otherProfile: p,
                                          );
                                        }
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            const SnackBar(content: Text('Added to Liked')),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ({double lat, double lon})? _myLocation() {
    final cached = SupabaseService.lastKnownLocation.value;
    if (cached != null) return cached;

    final me = SupabaseService.currentUserProfileCache.value;
    final lat = me?['latitude'];
    final lon = me?['longitude'];
    if (lat is num && lon is num) {
      return (lat: lat.toDouble(), lon: lon.toDouble());
    }
    return null;
  }

  double? _distanceMetersToOther(Map<String, dynamic> otherProfile) {
    final my = _myLocation();
    if (my == null) return null;
    final lat = otherProfile['latitude'];
    final lon = otherProfile['longitude'];
    if (lat is! num || lon is! num) return null;
    return Geolocator.distanceBetween(my.lat, my.lon, lat.toDouble(), lon.toDouble());
  }

  Widget _otherNameButton(String otherName) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _openOtherProfilePopup,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  otherName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherName = (widget.otherProfile?['name'] as String?) ?? 'Chat';
    final status = _conversationStatus();
    final chatEnabled = status == 'accepted';
    final showPending = status == 'pending';
    final showDeclined = status == 'declined';

    final title = Row(
      children: [
        Expanded(child: _otherNameButton(otherName)),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: title),
      body: SafeArea(
        child: Column(
          children: [
            if (showPending) _buildPendingNotice(),
            if (showDeclined) _buildDeclinedNotice(),
            if (chatEnabled) _buildPaymentNotice(),
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>?>(
                valueListenable: SupabaseService.chatMessagesCacheForConversation(widget.conversationId),
                builder: (context, value, _) {
                  if (value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Cache is [oldest...newest]; reverse for ListView reverse: true → [newest...oldest]
                  final filtered = value.where((m) => !_shouldHideSystemMessage(m)).toList();
                  final messages = List<Map<String, dynamic>>.from(filtered.reversed);
                  final showContent = _initialScrollApplied;
                  final showTopLoader = _isLoadingMore;
                  final hasUnread = _firstUnreadMessageIndex != null && _firstUnreadMessageId != null;
                  final firstUnreadIndexReversed = hasUnread
                      ? (messages.length - 1 - _firstUnreadMessageIndex!)
                      : null;
                  final itemCount = messages.length + (hasUnread ? 1 : 0) + (showTopLoader ? 1 : 0);
                  if (kDebugMode) {
                    debugPrint('[chat] ListView build: messageCount=${messages.length} '
                        'showContent=$showContent hasUnread=$hasUnread itemCount=$itemCount '
                        'firstUnreadIndexReversed=$firstUnreadIndexReversed');
                  }

                  return Stack(
                    children: [
                      if (!showContent)
                        const Center(child: CircularProgressIndicator()),
                      Opacity(
                        opacity: showContent ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !showContent,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification n) {
                              if (n is! ScrollUpdateNotification) return false;
                              final pos = n.metrics;
                              if (pos.pixels < pos.maxScrollExtent - _loadMoreThreshold) return false;
                              final now = DateTime.now();
                              if (_lastLoadMoreCheck != null && now.difference(_lastLoadMoreCheck!).inMilliseconds < 400) return false;
                              _lastLoadMoreCheck = now;
                              _loadOlderMessages();
                              return false;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              cacheExtent: 600,
                              itemCount: itemCount,
                              itemBuilder: (_, i) {
                              Widget child;
                              if (showTopLoader && i == itemCount - 1) {
                                child = const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )),
                                );
                              } else if (hasUnread && firstUnreadIndexReversed != null && i == firstUnreadIndexReversed) {
                                child = _buildUnreadDivider();
                              } else {
                                final msgIndex = (hasUnread && firstUnreadIndexReversed != null && i > firstUnreadIndexReversed)
                                    ? i - 1
                                    : i;
                                final m = messages[msgIndex];
                                final prev = msgIndex + 1 < messages.length ? messages[msgIndex + 1] : null;
                                child = _buildMessageBubble(m, prevMessage: prev);
                              }
                              return AutoScrollTag(
                                key: ValueKey(i),
                                controller: _scrollController,
                                index: i,
                                child: child,
                              );
                            },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildRequestActionArea(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Material(
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: (chatEnabled && !_isSending) ? () => _showProposeLessonSheet(context) : null,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primaryGreen, AppTheme.twinglPurple],
                          ),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: chatEnabled
                              ? Colors.white.withAlpha(250)
                              : Colors.white.withAlpha(120),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: chatEnabled,
                      decoration: InputDecoration(
                        hintText: showPending
                            ? 'Waiting for Accept'
                            : showDeclined
                                ? 'Declined'
                                : 'Message...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: (chatEnabled && !_isSending) ? _sendMessage : null,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primaryGreen, AppTheme.secondaryGold],
                          ),
                        ),
                        child: Icon(
                          Icons.send,
                          color: (chatEnabled && !_isSending)
                              ? Colors.white.withAlpha(250)
                              : Colors.white.withAlpha(120),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful content for the Scheduling bottom sheet.
/// Owns the TextEditingController so it is disposed when the sheet is closed.
class _ProposeLessonSheetContent extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSend;

  const _ProposeLessonSheetContent({required this.onSend});

  @override
  State<_ProposeLessonSheetContent> createState() =>
      _ProposeLessonSheetContentState();
}

class _ProposeLessonSheetContentState extends State<_ProposeLessonSheetContent> {
  late final TextEditingController _locationController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Widget _buildEditableRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
    );
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      borderRadius: border.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: border.borderRadius,
        child: InputDecorator(
          isFocused: false,
          decoration: InputDecoration(
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(icon, size: 22, color: theme.colorScheme.primary),
            suffixIcon: Icon(Icons.chevron_right, size: 22, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Scheduling',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildEditableRow(
            context: context,
            icon: Icons.calendar_today,
            label: DateFormat('EEEE, MMM d, y').format(_selectedDate),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null && mounted) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          const SizedBox(height: 8),
          _buildEditableRow(
            context: context,
            icon: Icons.access_time,
            label: _selectedTime.format(context),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (picked != null && mounted) {
                setState(() => _selectedTime = picked);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'e.g. Santa Teresa Library, Zoom',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final dt = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );
              widget.onSend(<String, dynamic>{
                'lessonDate': dt.toUtc().toIso8601String(),
                'location': _locationController.text.trim(),
                'durationMinutes': 60,
              });
              // onSend calls Navigator.pop(data), closing the sheet
            },
            child: const Text('Send Proposal'),
          ),
        ],
        ),
      ),
    );
  }
}
