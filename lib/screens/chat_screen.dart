import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../utils/calendar_date_parser.dart';

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
  final _scrollController = ScrollController();

  Map<String, dynamic>? _conversation;
  bool _isSending = false;

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationChannel;

  @override
  void initState() {
    super.initState();
    _loadConversationAndMessages();
    _subscribeToMessagesRealtime();
    _subscribeToConversationRealtime();
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _conversationChannel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationAndMessages() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Cache-first messages
    await SupabaseService.hydrateChatMessagesFromDisk(user.id, widget.conversationId);
    await SupabaseService.getChatMessagesCached(
      user.id,
      widget.conversationId,
      // If cache is empty, force refresh
      forceRefresh: SupabaseService.chatMessagesCacheForConversation(widget.conversationId).value == null,
      limit: 200,
    );

    // Conversation state
    final conv = await SupabaseService.getConversation(widget.conversationId);
    if (!mounted) return;
    setState(() => _conversation = conv);

    // Mark read
    await SupabaseService.markMessagesAsRead(widget.conversationId, user.id);

    _scrollToBottom();
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
            setState(() => _conversation = Map<String, dynamic>.from(newRow));
          },
        )
        .subscribe();
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

  bool _isSystem(Map<String, dynamic> m) => (m['type'] as String?) == 'system';
  bool _isRequest(Map<String, dynamic> m) => (m['type'] as String?) == 'request';

  bool _shouldHideSystemMessage(Map<String, dynamic> m) {
    if (!_isSystem(m)) return false;
    final text = (m['message_text'] as String?) ?? '';
    // Hide legacy calendar system messages in the new UX.
    return text.contains('Added') && text.contains('Calendar');
  }

  Future<void> _sendMessage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    // Optimistic cache insert
    final optimistic = <String, dynamic>{
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'conversation_id': widget.conversationId,
      'sender_id': user.id,
      'message_text': text,
      'type': 'text',
      'is_read': true,
      'created_at': DateTime.now().toIso8601String(),
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
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _acceptRequest() async {
    try {
      await SupabaseService.acceptTrainingRequest(widget.conversationId);
      final conv = await SupabaseService.getConversation(widget.conversationId);
      if (!mounted) return;
      setState(() => _conversation = conv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    }
  }

  Future<void> _declineRequest() async {
    try {
      await SupabaseService.declineTrainingRequest(widget.conversationId);
      final conv = await SupabaseService.getConversation(widget.conversationId);
      if (!mounted) return;
      setState(() => _conversation = conv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to decline: $e')));
    }
  }

  Widget _buildRequestActionArea() {
    final conv = _conversation;
    if (conv == null) return const SizedBox.shrink();
    final status = (conv['status'] as String?) ?? '';
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

  DateTime? _conversationScheduledStartLocal() {
    final s = _conversation?['scheduled_start_time'] as String?;
    if (s == null || s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    return dt?.toLocal();
  }

  DateTime? _conversationScheduledEndLocal() {
    final s = _conversation?['scheduled_end_time'] as String?;
    if (s == null || s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    return dt?.toLocal();
  }

  String _formatScheduledLabel(DateTime startLocal, DateTime endLocal) {
    final fmt = DateFormat('MMM d, h:mm a');
    return '${fmt.format(startLocal)} - ${DateFormat('h:mm a').format(endLocal)}';
  }

  // Pick the "active" proposed time for showing the schedule UI.
  ({DateTime startLocal, DateTime endLocal, String sourceText})? _activeScheduleProposal(
    List<Map<String, dynamic>> messages,
  ) {
    final scheduledStart = _conversationScheduledStartLocal();
    final scheduledEnd = _conversationScheduledEndLocal();
    if (scheduledStart != null && scheduledEnd != null) {
      return (startLocal: scheduledStart, endLocal: scheduledEnd, sourceText: _formatScheduledLabel(scheduledStart, scheduledEnd));
    }

    // No stored schedule yet: use latest parsed date/time message.
    for (int i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (_isSystem(m) || _isRequest(m)) continue;
      final text = (m['message_text'] as String?) ?? '';
      final dt = extractDateTime(text);
      if (dt != null) {
        final end = dt.add(const Duration(hours: 1));
        return (startLocal: dt, endLocal: end, sourceText: text);
      }
    }
    return null;
  }

  String _agreementStatusText({
    required bool isMeTrainer,
    required bool? trainerAgreed,
    required bool? traineeAgreed,
  }) {
    String show(bool? v) => v == null ? '—' : (v ? 'Yes' : 'No');
    final me = isMeTrainer ? show(trainerAgreed) : show(traineeAgreed);
    final other = isMeTrainer ? show(traineeAgreed) : show(trainerAgreed);
    return 'You: $me / Other: $other';
  }

  Future<bool> _isScheduleAlreadySavedForUser({
    required String userId,
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    try {
      final res = await Supabase.instance.client
          .from('calendar_events')
          .select('id')
          .eq('user_id', userId)
          .eq('conversation_id', widget.conversationId)
          .eq('start_time', startUtc.toIso8601String())
          .eq('end_time', endUtc.toIso8601String())
          .limit(1);
      return res is List && res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _addScheduleToCalendar({
    required String userId,
    required DateTime startLocal,
    required DateTime endLocal,
  }) async {
    try {
      final startUtc = startLocal.toUtc();
      final endUtc = endLocal.toUtc();

      // conflict check with other events (simple overlap window)
      final events = await SupabaseService.getCalendarEvents(
        userId: userId,
        startDate: startUtc.subtract(const Duration(hours: 8)),
        endDate: endUtc.add(const Duration(hours: 8)),
      );
      final hasConflict = events.any((e) {
        final convId = e['conversation_id']?.toString();
        // Ignore the same conversation event (idempotent)
        if (convId == widget.conversationId) return false;
        final s = DateTime.tryParse((e['start_time'] as String?) ?? '')?.toUtc();
        final en = DateTime.tryParse((e['end_time'] as String?) ?? '')?.toUtc();
        if (s == null || en == null) return false;
        return startUtc.isBefore(en) && endUtc.isAfter(s);
      });
      if (hasConflict) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calendar conflict detected.')),
        );
        return;
      }

      await SupabaseService.createCalendarEvent(
        userId: userId,
        title: 'Training',
        description: 'Scheduled from chat',
        startTime: startUtc,
        endTime: endUtc,
        conversationId: widget.conversationId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your calendar.')),
      );
      // No system message to the other user (per new UX).
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to calendar: $e')),
      );
    }
  }

  Widget _buildScheduleAgreementArea({
    required DateTime proposedStartLocal,
    required DateTime proposedEndLocal,
    required String dateTimeText,
  }) {
    final conv = _conversation;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (conv == null || currentUser == null) return const SizedBox.shrink();

    final status = (conv['status'] as String?) ?? '';
    if (status != 'accepted') return const SizedBox.shrink();

    final trainerId = conv['trainer_id'] as String?;
    final traineeId = conv['trainee_id'] as String?;
    final isMeTrainer = trainerId == currentUser.id;

    final trainerAgreed = conv['trainer_schedule_agreed'] as bool?;
    final traineeAgreed = conv['trainee_schedule_agreed'] as bool?;
    final scheduleState = conv['schedule_state'] as String?;

    final bothAgreed = trainerAgreed == true && traineeAgreed == true;

    final label = _formatScheduledLabel(proposedStartLocal, proposedEndLocal);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Do you agree $label ?'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final updated = await SupabaseService.respondToConversationSchedule(
                      conversationId: widget.conversationId,
                      proposedStartLocal: proposedStartLocal,
                      proposedEndLocal: proposedEndLocal,
                      agree: false,
                    );
                    if (!mounted) return;
                    setState(() => _conversation = updated ?? _conversation);
                  },
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final updated = await SupabaseService.respondToConversationSchedule(
                      conversationId: widget.conversationId,
                      proposedStartLocal: proposedStartLocal,
                      proposedEndLocal: proposedEndLocal,
                      agree: true,
                    );
                    if (!mounted) return;
                    setState(() => _conversation = updated ?? _conversation);
                  },
                  child: const Text('Yes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _agreementStatusText(
              isMeTrainer: isMeTrainer,
              trainerAgreed: trainerAgreed,
              traineeAgreed: traineeAgreed,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((scheduleState == 'declined') || (trainerAgreed == false) || (traineeAgreed == false))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Declined', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (bothAgreed) ...[
            const SizedBox(height: 10),
            FutureBuilder<bool>(
              future: _isScheduleAlreadySavedForUser(
                userId: currentUser.id,
                startUtc: proposedStartLocal.toUtc(),
                endUtc: proposedEndLocal.toUtc(),
              ),
              builder: (context, snap) {
                final saved = snap.data == true;
                if (saved) {
                  return const Text('Saved to your calendar');
                }
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _addScheduleToCalendar(
                      userId: currentUser.id,
                      startLocal: proposedStartLocal,
                      endLocal: proposedEndLocal,
                    ),
                    child: const Text('Add to Calendar'),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, {required ({DateTime startLocal, DateTime endLocal, String sourceText})? activeProposal}) {
    if (_shouldHideSystemMessage(m)) return const SizedBox.shrink();

    final currentUser = Supabase.instance.client.auth.currentUser;
    final senderId = m['sender_id'] as String?;
    final isMe = currentUser != null && senderId == currentUser.id;

    final text = (m['message_text'] as String?) ?? '';
    final type = (m['type'] as String?) ?? 'text';

    final isSystem = _isSystem(m);
    final bubbleColor = isSystem
        ? Colors.grey.shade200
        : isMe
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : Theme.of(context).colorScheme.surfaceVariant;
    final align = isSystem ? Alignment.center : (isMe ? Alignment.centerRight : Alignment.centerLeft);

    final dt = (!isSystem && !_isRequest(m)) ? extractDateTime(text) : null;
    final showScheduleForThisMessage = activeProposal != null &&
        dt != null &&
        dt.difference(activeProposal.startLocal).inMinutes.abs() < 1;

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isSystem ? Colors.grey.shade800 : null,
                    fontWeight: isSystem ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (showScheduleForThisMessage)
                _buildScheduleAgreementArea(
                  proposedStartLocal: activeProposal.startLocal,
                  proposedEndLocal: activeProposal.endLocal,
                  dateTimeText: activeProposal.sourceText,
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

  @override
  Widget build(BuildContext context) {
    final otherName = (widget.otherProfile?['name'] as String?) ?? 'Chat';

    final scheduledStart = _conversationScheduledStartLocal();
    final scheduledEnd = _conversationScheduledEndLocal();
    final showScheduledLabel = scheduledStart != null &&
        scheduledEnd != null &&
        (_conversation?['schedule_state'] as String?) == 'agreed';
    final scheduledLabel = showScheduledLabel ? _formatScheduledLabel(scheduledStart!, scheduledEnd!) : null;

    final title = Row(
      children: [
        Expanded(child: Text(otherName, overflow: TextOverflow.ellipsis)),
        if (scheduledLabel != null)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              'Scheduled: $scheduledLabel',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: title),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>?>(
                valueListenable: SupabaseService.chatMessagesCacheForConversation(widget.conversationId),
                builder: (context, value, _) {
                  if (value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = value.where((m) => !_shouldHideSystemMessage(m)).toList();
                  final activeProposal = _activeScheduleProposal(messages);

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (_, i) =>
                        _buildMessageBubble(messages[i], activeProposal: activeProposal),
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
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
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

