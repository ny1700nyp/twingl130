import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class CalendarTabScreen extends StatefulWidget {
  const CalendarTabScreen({super.key});

  @override
  State<CalendarTabScreen> createState() => _CalendarTabScreenState();
}

class _CalendarTabScreenState extends State<CalendarTabScreen> {
  int _selectedViewIndex = 0; // 0: Day, 1: Week, 2: Month
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _events = [];
          });
        }
        return;
      }

      // Get date range based on selected view
      final DateTime startDate;
      final DateTime endDate;
      switch (_selectedViewIndex) {
        case 0: // Day
          startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          endDate = startDate.add(const Duration(days: 1));
          break;
        case 1: // Week
          final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          endDate = startDate.add(const Duration(days: 7));
          break;
        case 2: // Month
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          endDate = nextMonth;
          break;
        default:
          startDate = DateTime.now();
          endDate = startDate.add(const Duration(days: 1));
      }

      // Retrieve events from Supabase
      final eventsList = await SupabaseService.getCalendarEvents(
        userId: currentUser.id,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _events = eventsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load calendar events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e')),
        );
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadEvents();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadEvents();
  }

  String _getViewTitle() {
    switch (_selectedViewIndex) {
      case 0:
        return DateFormat('MMM d, yyyy').format(_selectedDate);
      case 1:
        final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
      case 2:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      final startTimeStr = event['start_time'] as String?;
      if (startTimeStr == null) return false;
      try {
        final eventStart = DateTime.parse(startTimeStr).toLocal();
        return eventStart.year == date.year &&
            eventStart.month == date.month &&
            eventStart.day == date.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String _getEventTitle(Map<String, dynamic> event) {
    final title = event['title'] as String?;
    return title ?? 'Untitled';
  }

  String _getEventDescription(Map<String, dynamic> event) {
    final description = event['description'] as String?;
    return description ?? '';
  }

  DateTime _getEventStartTime(Map<String, dynamic> event) {
    final startTimeStr = event['start_time'] as String?;
    if (startTimeStr == null) return DateTime.now();
    try {
      return DateTime.parse(startTimeStr).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime _getEventEndTime(Map<String, dynamic> event) {
    final endTimeStr = event['end_time'] as String?;
    if (endTimeStr == null) {
      // If no end time, default to 1 hour after start
      return _getEventStartTime(event).add(const Duration(hours: 1));
    }
    try {
      return DateTime.parse(endTimeStr).toLocal();
    } catch (_) {
      return _getEventStartTime(event).add(const Duration(hours: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View selector and date navigation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // View type selector
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Day')),
                  ButtonSegment(value: 1, label: Text('Week')),
                  ButtonSegment(value: 2, label: Text('Month')),
                ],
                selected: {_selectedViewIndex},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedViewIndex = newSelection.first;
                  });
                  _loadEvents();
                },
              ),
              const SizedBox(height: 12),
              // Date navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDate(_selectedViewIndex == 2 ? -30 : _selectedViewIndex == 1 ? -7 : -1),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _getViewTitle(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton(
                            onPressed: _goToToday,
                            child: const Text('Today'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(_selectedViewIndex == 2 ? 30 : _selectedViewIndex == 1 ? 7 : 1),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Events list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add events from chat to see them here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                        ],
                      ),
                    )
                  : _buildEventsList(),
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    if (_selectedViewIndex == 0) {
      // Day view: show events for selected day, grouped by hour
      return _buildDayView();
    } else if (_selectedViewIndex == 1) {
      // Week view: show events for the week
      return _buildWeekView();
    } else {
      // Month view: show all events in the month
      return _buildMonthView();
    }
  }

  Widget _buildDayView() {
    final dayEvents = _getEventsForDate(_selectedDate);
    if (dayEvents.isEmpty) {
      return Center(
        child: Text(
          'No events on ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        final start = _getEventStartTime(event);
        final end = _getEventEndTime(event);
        final description = _getEventDescription(event);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(
              _getEventTitle(event),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            isThreeLine: description.isNotEmpty,
          ),
        );
      },
    );
  }

  Widget _buildWeekView() {
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final List<Widget> dayColumns = [];

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayEvents = _getEventsForDate(day);
      final isToday = day.year == DateTime.now().year &&
          day.month == DateTime.now().month &&
          day.day == DateTime.now().day;

      dayColumns.add(
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(day),
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dayEvents.length,
                    itemBuilder: (context, idx) {
                      final event = dayEvents[idx];
                      final start = _getEventStartTime(event);
                      final title = _getEventTitle(event);
                      final description = _getEventDescription(event);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(start),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dayColumns,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView() {
    final monthStart = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final monthEnd = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final List<Map<String, dynamic>> monthEvents = [];

    for (final event in _events) {
      final start = _getEventStartTime(event);
      if (start.isAfter(monthStart.subtract(const Duration(days: 1))) && start.isBefore(monthEnd.add(const Duration(days: 1)))) {
        monthEvents.add({
          'date': DateTime(start.year, start.month, start.day),
          'event': event,
        });
      }
    }

    // Group by date
    final Map<DateTime, List<Map<String, dynamic>>> eventsByDate = {};
    for (final item in monthEvents) {
      final date = item['date'] as DateTime;
      final event = item['event'] as Map<String, dynamic>;
      eventsByDate.putIfAbsent(date, () => []).add(event);
    }

    final sortedDates = eventsByDate.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEvents = eventsByDate[date]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('EEE').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            title: Text(
              DateFormat('MMMM yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${dayEvents.length} event${dayEvents.length != 1 ? 's' : ''}'),
            children: dayEvents.map((eventMap) {
              final start = _getEventStartTime(eventMap);
              final end = _getEventEndTime(eventMap);
              final title = _getEventTitle(eventMap);
              final description = _getEventDescription(eventMap);
              return ListTile(
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
                leading: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                isThreeLine: description.isNotEmpty,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
