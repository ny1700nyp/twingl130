import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance_formatter.dart';
import '../utils/time_utils.dart';
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
  final _scrollController = ScrollController();
  final _firstUnreadKey = GlobalKey();

  Map<String, dynamic>? _conversation;
  bool _isSending = false;
  /// ID of the oldest unread message from the other person (before marking read).
  String? _firstUnreadMessageId;
  /// Index in filtered messages list for scroll positioning (ListView.builder builds lazily).
  int? _firstUnreadMessageIndex;
  /// Total filtered message count when first unread was found (for proportional scroll).
  int? _filteredMessageCount;
  bool _paymentNoticeExpanded = false;
  bool _isLoadingMore = false;
  bool _hasNoMoreOlder = false;
  /// 초기 스크롤 적용 전까지 메시지 목록 숨김 (잘못된 위치 노출 방지)
  bool _initialScrollApplied = false;

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationChannel;

  @override
  void initState() {
    super.initState();
    SupabaseService.currentlyViewingConversationId = widget.conversationId;
    _scrollController.addListener(_onScroll);
    _loadConversationAndMessages();
    _subscribeToMessagesRealtime();
    _subscribeToConversationRealtime();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
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

    setState(() {
      _conversation = conv;
      _firstUnreadMessageId = firstUnreadId;
      _firstUnreadMessageIndex = firstUnreadIndex;
      _filteredMessageCount = filtered.length;
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
                if (kDebugMode) debugPrint('[chat] got request_accepted msg → refresh conversation');
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  static const double _loadMoreThreshold = 150;

  void _onScroll() {
    if (_isLoadingMore || _hasNoMoreOlder) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels <= _loadMoreThreshold) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _isLoadingMore || _hasNoMoreOlder) return;

    setState(() => _isLoadingMore = true);
    final oldOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;

    try {
      final count = await SupabaseService.loadOlderChatMessages(
        user.id,
        widget.conversationId,
        pageSize: 50,
      );
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (count < 50) _hasNoMoreOlder = true;
        });
        if (count > 0 && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients) return;
            final newOffset = oldOffset + count * _estimatedItemHeight;
            _scrollController.jumpTo(
              newOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            );
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  static const double _estimatedItemHeight = 72.0;

  void _scrollToInitialPosition() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pos = _scrollController.position;
      if (_firstUnreadMessageId != null && _firstUnreadMessageIndex != null) {
        // ListView.builder builds lazily; first jump to approximate position so the item gets built.
        // If approxOffset exceeds maxScrollExtent (estimate too high), use proportional position.
        final approxOffset = _firstUnreadMessageIndex! * _estimatedItemHeight;
        final totalCount = _filteredMessageCount ?? 200;
        final targetOffset = approxOffset <= pos.maxScrollExtent
            ? approxOffset.clamp(0.0, pos.maxScrollExtent)
            : (_firstUnreadMessageIndex! / totalCount) * pos.maxScrollExtent;
        _scrollController.jumpTo(targetOffset.clamp(0.0, pos.maxScrollExtent));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final hasContext = _firstUnreadKey.currentContext != null;
          if (hasContext) {
            Scrollable.ensureVisible(
              _firstUnreadKey.currentContext!,
              alignment: 0.0,
              duration: Duration.zero,
              curve: Curves.linear,
            );
          }
          if (mounted) setState(() => _initialScrollApplied = true);
        });
      } else if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent + 120,
        );
        if (mounted) setState(() => _initialScrollApplied = true);
      }
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
                    child: Text(
                      'Twingl connects you with neighbors, but we don\'t handle payments directly. '
                      'This keeps our service free and puts 100% of the fee in your tutor\'s pocket!\n\n'
                      'Please agree on a method that works for both of you, such as:\n'
                      '📱 Venmo / Zelle / PayPal\n'
                      '💵 Cash\n'
                      '☕️ Coffee or Meal (for casual sessions)\n\n'
                      'Note: For safety, we recommend paying after meeting in person.\n\n'
                      '💡 Tip: For online lessons, consider paying via PayPal for buyer protection, or use the 50/50 payment method.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(250),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
      // Date changed since previous message → show date.
      return DateFormat('yyyy-MM-dd').format(curr);
    }
    // Same day → show time, unless within 2 minutes of previous message.
    if (prev != null) {
      final diff = curr.difference(prev).inSeconds.abs();
      if (diff < 120) return null; // < 2 minutes → show nothing
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

    final currentUserId = currentUser?.id;
    final traineeId = _conversation?['trainee_id'] as String?;
    final isRequestSender = currentUserId != null && currentUserId == traineeId;
    final quoteGradient = isQuoteStyleSystem
        ? (isRequestSender
            ? [AppTheme.twinglMint, AppTheme.twinglPurple]
            : [AppTheme.twinglPurple, AppTheme.twinglMint])
        : null;

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
                          color: quoteGradient != null
                              ? Colors.white.withAlpha(250)
                              : isSystem
                                  ? Colors.grey.shade800
                                  : null,
                          fontWeight: isSystem || quoteGradient != null
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
    // 시트 드래그 시 재빌드되어도 로딩이 다시 뜨지 않도록, Future를 한 번만 생성
    final profileFuture = SupabaseService.getPublicProfile(otherUserId);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final h = media.size.height;
        final topPadding = media.padding.top;
        // 시트 상단이 인디케이터/노치 아래에 오도록 높이 제한 (슬라이드 다운으로 닫기 가능)
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
                                      subParts.join('  •  '),
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
        if (showPending || showDeclined)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (showPending ? Colors.orange : Colors.red).withAlpha(38),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                showPending ? 'Pending' : 'Declined',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: showPending ? Colors.orange.shade900 : Colors.red.shade900,
                ),
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: title),
      body: SafeArea(
        child: Column(
          children: [
            if (chatEnabled) _buildPaymentNotice(),
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>?>(
                valueListenable: SupabaseService.chatMessagesCacheForConversation(widget.conversationId),
                builder: (context, value, _) {
                  if (value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = value.where((m) => !_shouldHideSystemMessage(m)).toList();
                  final showContent = _initialScrollApplied;
                  final showTopLoader = _isLoadingMore;
                  final itemCount = messages.length + (showTopLoader ? 1 : 0);

                  return Stack(
                    children: [
                      if (!showContent)
                        const Center(child: CircularProgressIndicator()),
                      Opacity(
                        opacity: showContent ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !showContent,
                          child: ListView.builder(
                    controller: _scrollController,
                    itemCount: itemCount,
                    itemBuilder: (_, i) {
                      if (showTopLoader && i == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )),
                        );
                      }
                      final msgIndex = showTopLoader ? i - 1 : i;
                      final m = messages[msgIndex];
                      final isFirstUnread = _firstUnreadMessageId != null &&
                          (m['id']?.toString() == _firstUnreadMessageId);
                      final bubble = _buildMessageBubble(
                        m,
                        prevMessage: msgIndex > 0 ? messages[msgIndex - 1] : null,
                      );
                      if (isFirstUnread) {
                        return Column(
                          key: _firstUnreadKey,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildUnreadDivider(),
                            bubble,
                          ],
                        );
                      }
                      return bubble;
                    },
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
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      // Keep input active even while sending; only disable the send button.
                      enabled: chatEnabled,
                      decoration: InputDecoration(
                        hintText: showPending
                            ? 'Pending… (wait for accept)'
                            : showDeclined
                                ? 'Declined'
                                : 'Message…',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: (!chatEnabled || _isSending) ? null : _sendMessage,
                    icon: const Icon(Icons.send),
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

