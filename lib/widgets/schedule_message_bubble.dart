import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Renders a chat bubble for schedule proposal messages with an "Add to Calendar" action.
class ScheduleMessageBubble extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final String? senderDisplayName;
  final bool isMe;
  final String? timestamp;

  const ScheduleMessageBubble({
    super.key,
    required this.metadata,
    this.senderDisplayName,
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
          const SnackBar(content: Text('Invalid date in this proposal')),
        );
      }
      return;
    }
    // Use local time for the calendar event
    final localDt = dt.isUtc ? dt.toLocal() : dt;
    final endDate = localDt.add(Duration(minutes: _durationMinutes));
    final title = senderDisplayName != null && senderDisplayName!.isNotEmpty
        ? 'Twingl lesson $senderDisplayName'
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
          const SnackBar(content: Text('Added to calendar')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to calendar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Scheduler',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formattedDateTime,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (_location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _location,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToCalendar(context),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Add to Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
