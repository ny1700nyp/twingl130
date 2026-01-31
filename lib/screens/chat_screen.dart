import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../utils/calendar_date_parser.dart';
import '../utils/time_utils.dart';

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

  Map<String, dynamic>? _conversation;
  bool _isSending = false;
  bool _scheduleSupported = true;

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
    _inputFocusNode.dispose();
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
    setState(() {
      _conversation = conv;
      // DB schema must include these columns for scheduling UX to work.
      // If missing, hide schedule UI and show a clear message when user interacts.
      _scheduleSupported = conv != null &&
          conv.containsKey('schedule_state') &&
          conv.containsKey('scheduled_start_time') &&
          conv.containsKey('scheduled_end_time') &&
          conv.containsKey('trainer_schedule_agreed') &&
          conv.containsKey('trainee_schedule_agreed');
    });

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

  ({String skill, String method})? _extractRequestInfo(Map<String, dynamic> m) {
    if ((m['type'] as String?) != 'request') return null;
    // Prefer metadata
    final metadata = m['metadata'];
    if (metadata is Map) {
      final mm = Map<String, dynamic>.from(metadata);
      final skill = (mm['skill'] as String?)?.trim();
      final method = (mm['method'] as String?)?.trim();
      if (skill != null && skill.isNotEmpty && method != null && method.isNotEmpty) {
        return (skill: skill, method: method);
      }
    }
    // Fallback to text pattern: "Request: skill (method)"
    final text = (m['content'] as String?) ?? (m['message_text'] as String?) ?? '';
    final match = RegExp(r'^Request:\s*(.+?)\s*\((.+?)\)\s*$', caseSensitive: false).firstMatch(text.trim());
    if (match != null) {
      final skill = match.group(1)?.trim() ?? '';
      final method = match.group(2)?.trim() ?? '';
      if (skill.isNotEmpty && method.isNotEmpty) return (skill: skill, method: method);
    }
    return null;
  }

  ({String skill, String method})? _latestRequestInfo(List<Map<String, dynamic>> messages) {
    for (int i = messages.length - 1; i >= 0; i--) {
      final info = _extractRequestInfo(messages[i]);
      if (info != null) return info;
    }
    return null;
  }

  String _prettyMethod(String method) {
    final m = method.trim().toLowerCase();
    if (m == 'onsite' || m == 'on-site' || m == 'inperson' || m == 'in-person') return 'Onsite';
    if (m == 'online') return 'Online';
    return method.trim();
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
        messageText: 'Accepted. You can chat now. Please discuss your schedule.',
        type: 'system',
        metadata: const <String, dynamic>{'kind': 'request_accepted'},
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
    final scheduleState = (_conversation?['schedule_state'] as String?)?.trim().toLowerCase();

    // Latest parsed date/time message (new proposal)
    ({DateTime startLocal, DateTime endLocal, String sourceText})? latestParsed;
    for (int i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (_isSystem(m) || _isRequest(m)) continue;
      final text = (m['content'] as String?) ?? (m['message_text'] as String?) ?? '';
      final dt = extractDateTime(text);
      if (dt != null) {
        final end = dt.add(const Duration(hours: 1));
        latestParsed = (startLocal: dt, endLocal: end, sourceText: text);
        break;
      }
    }

    // If a new date/time is mentioned again, treat it as a new proposal even if we already had an agreed schedule.
    if (latestParsed != null) {
      if (scheduledStart == null || scheduledEnd == null) return latestParsed;
      if (scheduleState == null || scheduleState == 'declined') return latestParsed;
      final diffMin = latestParsed.startLocal.difference(scheduledStart).inMinutes.abs();
      if (diffMin >= 1) return latestParsed;
    }

    // Fallback to stored schedule (already agreed) if no new proposal.
    if (scheduledStart != null && scheduledEnd != null) {
      return (
        startLocal: scheduledStart,
        endLocal: scheduledEnd,
        sourceText: _formatScheduledLabel(scheduledStart, scheduledEnd),
      );
    }
    return latestParsed;
  }

  Future<void> _respondSchedule({
    required DateTime proposedStartLocal,
    required DateTime proposedEndLocal,
    required bool agree,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final conv = _conversation;
    if (currentUser == null || conv == null) return;
    if (!_scheduleSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduling requires DB migration: run MIGRATE_CONVERSATIONS_SCHEDULE.sql'),
        ),
      );
      return;
    }

    final trainerId = conv['trainer_id'] as String?;
    final traineeId = conv['trainee_id'] as String?;
    final isMeTrainer = trainerId == currentUser.id;

    bool? prevTrainerAgreed = conv['trainer_schedule_agreed'] as bool?;
    bool? prevTraineeAgreed = conv['trainee_schedule_agreed'] as bool?;

    // If this is a different proposal than the stored schedule, reset both agree states (UI + DB behavior).
    final existingStartLocal = TimeUtils.tryParseIsoToLocal(conv['scheduled_start_time'] as String?);
    final existingState = (conv['schedule_state'] as String?)?.trim().toLowerCase();
    final isDifferentProposal = existingStartLocal == null ||
        existingStartLocal.difference(proposedStartLocal).inMinutes.abs() >= 1 ||
        existingState == null ||
        existingState == 'declined';
    if (isDifferentProposal) {
      prevTrainerAgreed = null;
      prevTraineeAgreed = null;
    }

    final nextTrainerAgreed = isMeTrainer ? agree : prevTrainerAgreed;
    final nextTraineeAgreed = isMeTrainer ? prevTraineeAgreed : agree;

    String nextState = 'proposed';
    if (agree == false) {
      nextState = 'declined';
    } else if (nextTrainerAgreed == true && nextTraineeAgreed == true) {
      nextState = 'agreed';
    }

    // Optimistic UI update so the pressed button highlights immediately.
    setState(() {
      _conversation = <String, dynamic>{
        ...conv,
        'scheduled_start_time': proposedStartLocal.toUtc().toIso8601String(),
        'scheduled_end_time': proposedEndLocal.toUtc().toIso8601String(),
        'schedule_state': nextState,
        'trainer_schedule_agreed': nextTrainerAgreed,
        'trainee_schedule_agreed': nextTraineeAgreed,
        'updated_at': DateTime.now().toIso8601String(),
      };
    });

    try {
      final updated = await SupabaseService.respondToConversationSchedule(
        conversationId: widget.conversationId,
        proposedStartLocal: proposedStartLocal,
        proposedEndLocal: proposedEndLocal,
        agree: agree,
      );
      if (!mounted) return;
      if (updated != null) {
        if (kDebugMode) {
          debugPrint(
            '[chat] schedule updated state=${updated['schedule_state']} '
            'trainer=${updated['trainer_schedule_agreed']} trainee=${updated['trainee_schedule_agreed']}',
          );
        }
        setState(() => _conversation = updated);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[chat] schedule update failed: $e');
      if (!mounted) return;
      // Common case: DB migration not applied or schema cache not refreshed.
      final msg = e.toString();
      final missingColumn = msg.contains("PGRST204") && msg.contains("schedule_state");
      if (missingColumn) {
        setState(() {
          _conversation = conv; // revert optimistic UI
          _scheduleSupported = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DB missing schedule columns. Run MIGRATE_CONVERSATIONS_SCHEDULE.sql then reload schema.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update schedule: $e')),
      );
    }
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

      final otherName = ((widget.otherProfile?['name'] as String?) ?? 'Training').trim();
      final cachedMessages =
          SupabaseService.chatMessagesCacheForConversation(widget.conversationId).value ??
              const <Map<String, dynamic>>[];
      final latestReq = _latestRequestInfo(cachedMessages);
      final title = latestReq == null
          ? 'Training with $otherName'
          : '$otherName - ${latestReq.skill} (${_prettyMethod(latestReq.method)})';
      final description = latestReq == null
          ? 'Scheduled from chat'
          : 'Lesson: ${latestReq.skill}\nLesson Location: ${_prettyMethod(latestReq.method)}';

      await SupabaseService.createCalendarEvent(
        userId: userId,
        title: title,
        description: description,
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
    if (!_scheduleSupported) return const SizedBox.shrink();

    final status = _conversationStatus();
    if (status != 'accepted') return const SizedBox.shrink();

    final trainerId = conv['trainer_id'] as String?;
    final traineeId = conv['trainee_id'] as String?;
    final isMeTrainer = trainerId == currentUser.id;

    // If this message is proposing a different time than the current stored schedule,
    // ignore previous agree flags so user must confirm again.
    final existingStartLocal = TimeUtils.tryParseIsoToLocal(conv['scheduled_start_time'] as String?);
    final existingState = (conv['schedule_state'] as String?)?.trim().toLowerCase();
    final isDifferentProposal = existingStartLocal == null ||
        existingStartLocal.difference(proposedStartLocal).inMinutes.abs() >= 1 ||
        existingState == null ||
        existingState == 'declined';

    final trainerAgreed = isDifferentProposal ? null : (conv['trainer_schedule_agreed'] as bool?);
    final traineeAgreed = isDifferentProposal ? null : (conv['trainee_schedule_agreed'] as bool?);
    final scheduleState = isDifferentProposal ? 'proposed' : (conv['schedule_state'] as String?);

    final bothAgreed = trainerAgreed == true && traineeAgreed == true;
    final myChoice = isMeTrainer ? trainerAgreed : traineeAgreed;
    final noSelected = myChoice == false;
    final yesSelected = myChoice == true;

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
                child: noSelected
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        onPressed: () => _respondSchedule(
                          proposedStartLocal: proposedStartLocal,
                          proposedEndLocal: proposedEndLocal,
                          agree: false,
                        ),
                        child: const Text('No'),
                      )
                    : OutlinedButton(
                        onPressed: () => _respondSchedule(
                          proposedStartLocal: proposedStartLocal,
                          proposedEndLocal: proposedEndLocal,
                          agree: false,
                        ),
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: yesSelected
                    ? ElevatedButton(
                        onPressed: () => _respondSchedule(
                          proposedStartLocal: proposedStartLocal,
                          proposedEndLocal: proposedEndLocal,
                          agree: true,
                        ),
                        child: const Text('Yes'),
                      )
                    : OutlinedButton(
                        onPressed: () => _respondSchedule(
                          proposedStartLocal: proposedStartLocal,
                          proposedEndLocal: proposedEndLocal,
                          agree: true,
                        ),
                        child: const Text('Yes'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saved to your calendar'),
                      const SizedBox(height: 6),
                      Text(
                        'Now discuss the lesson location and fee.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  );
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

  Widget _buildMessageBubble(
    Map<String, dynamic> m, {
    required Map<String, dynamic>? prevMessage,
    required ({DateTime startLocal, DateTime endLocal, String sourceText})? activeProposal,
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
    final status = _conversationStatus();
    final chatEnabled = status == 'accepted';
    final showPending = status == 'pending';
    final showDeclined = status == 'declined';

    final scheduledStart = _conversationScheduledStartLocal();
    final scheduledEnd = _conversationScheduledEndLocal();
    final showScheduledLabel = scheduledStart != null &&
        scheduledEnd != null &&
        (_conversation?['schedule_state'] as String?) == 'agreed';
    final scheduledLabel = showScheduledLabel ? _formatScheduledLabel(scheduledStart!, scheduledEnd!) : null;

    final title = Row(
      children: [
        Expanded(child: Text(otherName, overflow: TextOverflow.ellipsis)),
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
                        _buildMessageBubble(
                          messages[i],
                          prevMessage: i > 0 ? messages[i - 1] : null,
                          activeProposal: activeProposal,
                        ),
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

