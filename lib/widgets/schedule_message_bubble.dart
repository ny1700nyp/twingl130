import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Renders a chat bubble for schedule proposal messages with an "Add to Calendar" action.
class ScheduleMessageBubble extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final String? senderDisplayName;
  /// Name of the other party in the chat (for calendar event title). Used for both sender and receiver.
  final String? otherPartyNameForCalendar;
  final bool isMe;
  final String? timestamp;

  const ScheduleMessageBubble({
    super.key,
    required this.metadata,
    this.senderDisplayName,
    this.otherPartyNameForCalendar,
    required this.isMe,
    this.timestamp,
  });

  DateTime? get _lessonDate {
    final s = metadata['lessonDate'] as String?;
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String get _location => (metadata['location'] as String?)?.trim() ?? '';
  int get _durationMinutes => (metadata['durationMinutes'] as int?) ?? 60;

  String get _formattedDateTime {
    final dt = _lessonDate;
    if (dt == null) return '—';
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateFormat('MMM d (EEE), h:mm a').format(local);
  }

  Future<void> _addToCalendar(BuildContext context) async {
    final dt = _lessonDate;
    if (dt == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.invalidDateInProposal)),
        );
      }
      return;
    }
    // Use local time for the calendar event
    final localDt = dt.isUtc ? dt.toLocal() : dt;
    final endDate = localDt.add(Duration(minutes: _durationMinutes));
    final name = otherPartyNameForCalendar?.trim();
    final title = name != null && name.isNotEmpty
        ? 'Twingl lesson $name'
        : 'Twingl lesson';

    final event = Event(
      title: title,
      description: 'Twingl lesson',
      location: _location,
      startDate: localDt,
      endDate: endDate,
    );

    try {
      Add2Calendar.addEvent2Cal(event);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.addedToCalendar)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddToCalendar(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _addToCalendar(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.addToCalendar,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.calendar_month, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _formattedDateTime,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
