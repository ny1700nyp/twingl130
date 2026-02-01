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

  double _eventDialogWidth(BuildContext context) {
    // Keep dialog width stable regardless of text length,
    // while still fitting on smaller screens.
    final w = MediaQuery.of(context).size.width;
    return (w - 80).clamp(320.0, 420.0);
  }

  int _todMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

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
      if (_selectedViewIndex == 2) {
        // Month view: move by calendar month (not +/-30 days)
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + (days.sign), 1);
      } else if (_selectedViewIndex == 1) {
        // Week view: move by 7 days
        _selectedDate = _selectedDate.add(Duration(days: 7 * (days.sign)));
      } else {
        _selectedDate = _selectedDate.add(Duration(days: days));
      }
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

  void _goToDay(DateTime day) {
    setState(() {
      _selectedViewIndex = 0;
      _selectedDate = DateTime(day.year, day.month, day.day);
    });
    _loadEvents();
  }

  Future<void> _openEventDetail(Map<String, dynamic> event) async {
    final id = event['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final title = _getEventTitle(event);
    final description = _getEventDescription(event);
    final start = _getEventStartTime(event);
    final end = _getEventEndTime(event);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('MMM d, yyyy').format(start)}  •  ${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(description),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showEditEventDialog(event);
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmDeleteEvent(event);
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteEvent(Map<String, dynamic> event) async {
    final id = event['id']?.toString() ?? '';
    if (id.isEmpty) return;

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await SupabaseService.deleteCalendarEvent(eventId: id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted.')));
      _loadEvents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _showEditEventDialog(Map<String, dynamic> event) async {
    final id = event['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final titleCtrl = TextEditingController(text: _getEventTitle(event));
    final descCtrl = TextEditingController(text: _getEventDescription(event));
    DateTime start = _getEventStartTime(event);
    DateTime end = _getEventEndTime(event);

    Future<void> pickStart(StateSetter setLocal) async {
      final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
      if (t == null) return;
      if (!mounted) return;
      setLocal(() {
        // Keep the same date; only adjust time.
        start = DateTime(start.year, start.month, start.day, t.hour, t.minute);
        if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));
      });
    }

    Future<void> pickEnd(StateSetter setLocal) async {
      // Disallow selecting an end time before (or equal to) start time.
      while (true) {
        final minEnd = start.add(const Duration(minutes: 1));
        final initial = end.isAfter(minEnd) ? end : minEnd;
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initial),
        );
        if (t == null) return;
        if (!mounted) return;

        final pickedMinutes = _todMinutes(t);
        final minMinutes = _todMinutes(TimeOfDay.fromDateTime(minEnd));
        if (pickedMinutes < minMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time.')),
          );
          continue; // reopen time picker
        }

        setLocal(() {
          // Keep the same date; only adjust time.
          end = DateTime(end.year, end.month, end.day, t.hour, t.minute);
          if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));
        });
        return;
      }
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Edit event'),
          content: SizedBox(
            width: _eventDialogWidth(ctx),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    maxLines: 1,
                    minLines: 1,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    minLines: 3,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle:
                        Text('${DateFormat('MMM d, yyyy').format(start)} ${DateFormat('h:mm a').format(start)}'),
                    onTap: () => pickStart(setLocal),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End'),
                    subtitle: Text('${DateFormat('MMM d, yyyy').format(end)} ${DateFormat('h:mm a').format(end)}'),
                    onTap: () => pickEnd(setLocal),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final newTitle = titleCtrl.text.trim();
    if (newTitle.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }
    if (!end.isAfter(start)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End must be after start.')));
      return;
    }

    try {
      await SupabaseService.updateCalendarEvent(
        eventId: id,
        title: newTitle,
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        startTime: start,
        endTime: end,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
      _loadEvents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      titleCtrl.dispose();
      descCtrl.dispose();
    }
  }

  Future<void> _showAddEventDialog() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not logged in.')));
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final now = DateTime.now();
    final sameDay = sel.year == now.year && sel.month == now.month && sel.day == now.day;

    // No default display for start/end; user must pick time.
    // We still provide a reasonable initial time in the picker.
    DateTime? start;
    DateTime? end;
    final initialStartHour = sameDay ? (now.hour + 1).clamp(0, 23) : 10;
    final initialStart = DateTime(sel.year, sel.month, sel.day, initialStartHour, 0);

    Future<void> pickStart(StateSetter setLocal) async {
      final base = start ?? initialStart;
      final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
      if (t == null) return;
      if (!mounted) return;
      setLocal(() {
        // Date is already selected by Day view; only pick time.
        start = DateTime(sel.year, sel.month, sel.day, t.hour, t.minute);
        // If previously selected end is now invalid, clear it so user must re-pick.
        if (end != null && start != null && !end!.isAfter(start!)) {
          end = null;
        }
      });
    }

    Future<void> pickEnd(StateSetter setLocal) async {
      if (start == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start time first.')),
        );
        return;
      }
      // Disallow selecting an end time before (or equal to) start time.
      while (true) {
        final minEnd = start!.add(const Duration(minutes: 1));
        // If start is too late in the day, there may be no valid end time on the same date.
        final sameDate = minEnd.year == sel.year && minEnd.month == sel.month && minEnd.day == sel.day;
        if (!sameDate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start time is too late. Please choose an earlier start time.')),
          );
          return;
        }

        final defaultEnd = DateTime(sel.year, sel.month, sel.day, start!.hour, start!.minute)
            .add(const Duration(hours: 1));
        final initial = (end != null && end!.isAfter(minEnd))
            ? end!
            : (defaultEnd.isAfter(minEnd) ? defaultEnd : minEnd);
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initial),
        );
        if (t == null) return;
        if (!mounted) return;

        final pickedMinutes = _todMinutes(t);
        final minMinutes = _todMinutes(TimeOfDay.fromDateTime(minEnd));
        if (pickedMinutes < minMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time.')),
          );
          continue; // reopen time picker
        }

        setLocal(() {
          // Date is already selected by Day view; only pick time.
          end = DateTime(sel.year, sel.month, sel.day, t.hour, t.minute);
        });
        return;
      }
    }

    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add event'),
          content: SizedBox(
            width: _eventDialogWidth(ctx),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    maxLines: 1,
                    minLines: 1,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    minLines: 3,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle: Text(
                      start == null ? 'Select time' : DateFormat('h:mm a').format(start!),
                      style: TextStyle(
                        color: start == null
                            ? Theme.of(ctx).colorScheme.onSurface.withOpacity(0.55)
                            : null,
                      ),
                    ),
                    onTap: () => pickStart(setLocal),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End'),
                    subtitle: Text(
                      end == null
                          ? (start == null ? 'Select start time first' : 'Select time')
                          : DateFormat('h:mm a').format(end!),
                      style: TextStyle(
                        color: end == null
                            ? Theme.of(ctx).colorScheme.onSurface.withOpacity(0.55)
                            : null,
                      ),
                    ),
                    onTap: start == null ? null : () => pickEnd(setLocal),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) {
      titleCtrl.dispose();
      descCtrl.dispose();
      return;
    }

    final newTitle = titleCtrl.text.trim();
    final newDesc = descCtrl.text.trim();

    titleCtrl.dispose();
    descCtrl.dispose();

    if (newTitle.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }
    if (start == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start time is required.')));
      return;
    }
    if (end == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time is required.')));
      return;
    }
    if (!end!.isAfter(start!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End must be after start.')));
      return;
    }

    try {
      await SupabaseService.createCalendarEvent(
        userId: currentUser.id,
        title: newTitle,
        description: newDesc.isEmpty ? '' : newDesc,
        startTime: start!,
        endTime: end!,
        conversationId: null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added.')));
      _loadEvents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
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
                    // Always start from "today / this week / this month" when switching tabs.
                    _selectedDate = DateTime.now();
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
                    onPressed: () => _changeDate(_selectedViewIndex == 2 ? -1 : _selectedViewIndex == 1 ? -7 : -1),
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
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(_selectedViewIndex == 2 ? 1 : _selectedViewIndex == 1 ? 7 : 1),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Events list
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildEventsList(),
              ),
              if (!_isLoading && _selectedViewIndex == 0)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: _showAddEventDialog,
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          ),
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
            onTap: () => _openEventDetail(event),
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
                InkWell(
                  onTap: () => _goToDay(day),
                  child: Padding(
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
                      return InkWell(
                        onTap: () => _openEventDetail(event),
                        child: Container(
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
    final gridStart = monthStart.subtract(Duration(days: monthStart.weekday - 1)); // Monday start
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));

    const weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    Widget dayCell(DateTime day) {
      final inMonth = day.month == _selectedDate.month;
      final isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
      final isSelected = day.year == _selectedDate.year && day.month == _selectedDate.month && day.day == _selectedDate.day;
      final dayEvents = _getEventsForDate(day);
      final maxPreview = 2;
      final previews = dayEvents.take(maxPreview).toList();
      final more = dayEvents.length - previews.length;

      return InkWell(
        onTap: () => _goToDay(day),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35) : null,
            borderRadius: BorderRadius.circular(10),
            border: isToday ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: inMonth
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
              const SizedBox(height: 2),
              for (final e in previews)
                InkWell(
                  onTap: () => _openEventDetail(e),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _getEventTitle(e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '+$more',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              for (final w in weekLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.95,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: days.length,
              itemBuilder: (context, i) => dayCell(days[i]),
            ),
          ),
        ],
      ),
    );
  }
}
