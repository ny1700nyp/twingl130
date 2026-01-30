/// Helper to extract date/time from chat messages for calendar event detection.
/// Returns a [DateTime] in local time, or null if no valid pattern is found.
DateTime? extractDateTime(String message) {
  if (message.isEmpty) return null;
  final trimmed = message.trim();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  try {
    // 1. YYYY-MM-DD or YYYY-MM-DD HH:mm or YYYY-MM-DDTHH:mm
    final isoDate = RegExp(
      r'(\d{4})-(\d{2})-(\d{2})(?:[T\s]+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
      caseSensitive: false,
    );
    final isoMatch = isoDate.firstMatch(trimmed);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      final h = isoMatch.group(4) != null ? int.parse(isoMatch.group(4)!) : 9;
      final min = isoMatch.group(5) != null ? int.parse(isoMatch.group(5)!) : 0;
      final sec = isoMatch.group(6) != null ? int.parse(isoMatch.group(6)!) : 0;
      if (_isValidDate(y, m, d) && _isValidTime(h, min, sec)) {
        return DateTime(y, m, d, h, min, sec);
      }
    }

    // 2. "the day after tomorrow [time]" (e.g. "the day after tomorrow 2AM")
    final dayAfterTomorrow = RegExp(
      r'the\s+day\s+after\s+tomorrow\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final dayAfterTomorrowMatch = dayAfterTomorrow.firstMatch(trimmed);
    if (dayAfterTomorrowMatch != null) {
      final base = today.add(const Duration(days: 2)); // day after tomorrow = +2 days
      final h = int.parse(dayAfterTomorrowMatch.group(1)!);
      final min = dayAfterTomorrowMatch.group(2) != null ? int.parse(dayAfterTomorrowMatch.group(2)!) : 0;
      final amPm = dayAfterTomorrowMatch.group(3)?.toLowerCase();
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0)) {
        return DateTime(base.year, base.month, base.day, hour24, min, 0);
      }
    }

    // 2.5. "tomorrow at [time]" or "tomorrow [time]"
    final tomorrow = RegExp(
      r'tomorrow\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final tomorrowMatch = tomorrow.firstMatch(trimmed);
    if (tomorrowMatch != null) {
      final base = today.add(const Duration(days: 1));
      final h = int.parse(tomorrowMatch.group(1)!);
      final min = tomorrowMatch.group(2) != null ? int.parse(tomorrowMatch.group(2)!) : 0;
      final amPm = tomorrowMatch.group(3)?.toLowerCase();
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0)) {
        return DateTime(base.year, base.month, base.day, hour24, min, 0);
      }
    }

    const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    // 3. "this [weekday] [time]" (e.g. "this sunday 5AM") = upcoming occurrence of that weekday
    final thisWeekday = RegExp(
      r'this\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );
    final thisWeekdayMatch = thisWeekday.firstMatch(trimmed);
    if (thisWeekdayMatch != null) {
      final name = thisWeekdayMatch.group(1)!.toLowerCase();
      final targetWeekday = weekdays.indexOf(name) + 1;
      var day = today;
      while (day.weekday != targetWeekday) {
        day = day.add(const Duration(days: 1));
      }
      // If that day is in the past (e.g. we're past Sunday this week), use next week
      if (day.isBefore(today)) {
        day = day.add(const Duration(days: 7));
      }
      final hStr = thisWeekdayMatch.group(2);
      final minStr = thisWeekdayMatch.group(3);
      final amPm = thisWeekdayMatch.group(4)?.toLowerCase();
      final h = hStr != null ? int.parse(hStr) : 9;
      final min = minStr != null ? int.parse(minStr) : 0;
      final hour24 = _to24h(h, min, amPm);
      if (hour24 == null) return DateTime(day.year, day.month, day.day, 9, 0, 0);
      if (_isValidTime(hour24, min, 0)) {
        return DateTime(day.year, day.month, day.day, hour24, min, 0);
      }
    }

    // 3.2. "next [weekday]" / "the next [weekday]" = the weekday *after* "this" (i.e. +7 days from upcoming)
    final nextWeekday = RegExp(
      r'(?:the\s+)?next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?)?',
      caseSensitive: false,
    );
    final nextMatch = nextWeekday.firstMatch(trimmed);
    if (nextMatch != null) {
      final name = nextMatch.group(1)!.toLowerCase();
      final targetWeekday = weekdays.indexOf(name) + 1;
      var day = today;
      while (day.weekday != targetWeekday) {
        day = day.add(const Duration(days: 1));
      }
      if (day.isBefore(today)) {
        day = day.add(const Duration(days: 7));
      }
      // "next Sunday" = the Sunday after "this Sunday" → add 7 days
      day = day.add(const Duration(days: 7));
      final hStr = nextMatch.group(2);
      final minStr = nextMatch.group(3);
      final amPm = nextMatch.group(4)?.toLowerCase();
      final h = hStr != null ? int.parse(hStr) : 9;
      final min = minStr != null ? int.parse(minStr) : 0;
      final hour24 = _to24h(h, min, amPm);
      if (hour24 == null) return DateTime(day.year, day.month, day.day, 9, 0, 0);
      if (_isValidTime(hour24, min, 0)) {
        return DateTime(day.year, day.month, day.day, hour24, min, 0);
      }
    }

    // 3.5. "[weekday] [time]" without "this/next" (e.g. "saturday 8AM", "sunday 7:00 PM") = same as "this [weekday]"
    final weekdayAndTime = RegExp(
      r'(?<!next\s)(?<!this\s)\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final weekdayMatch = weekdayAndTime.firstMatch(trimmed);
    if (weekdayMatch != null) {
      final name = weekdayMatch.group(1)!.toLowerCase();
      final targetWeekday = weekdays.indexOf(name) + 1;
      var day = today;
      while (day.weekday != targetWeekday) {
        day = day.add(const Duration(days: 1));
      }
      // If today is that weekday, use today; otherwise we already have the next occurrence
      final hStr = weekdayMatch.group(2);
      final minStr = weekdayMatch.group(3);
      final amPm = weekdayMatch.group(4)?.toLowerCase();
      final h = hStr != null ? int.parse(hStr) : 9;
      final min = minStr != null ? int.parse(minStr) : 0;
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0)) {
        return DateTime(day.year, day.month, day.day, hour24, min, 0);
      }
    }

    // 3.6. "next month [ordinal] [time]" (e.g. "next month 10th 9AM")
    final nextMonthOrdinal = RegExp(
      r'next\s+month\s+(\d{1,2})(?:st|nd|rd|th)?\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final nextMonthMatch = nextMonthOrdinal.firstMatch(trimmed);
    if (nextMonthMatch != null) {
      final d = int.parse(nextMonthMatch.group(1)!);
      final hStr = nextMonthMatch.group(2);
      final minStr = nextMonthMatch.group(3);
      final amPm = nextMonthMatch.group(4)?.toLowerCase();
      final h = hStr != null ? int.parse(hStr) : 9;
      final min = minStr != null ? int.parse(minStr) : 0;
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0) && d >= 1 && d <= 31) {
        var base = DateTime(now.year, now.month + 1, 1); // first day of next month
        final lastDay = DateTime(base.year, base.month + 1, 0).day;
        final day = d > lastDay ? lastDay : d;
        if (_isValidDate(base.year, base.month, day)) {
          return DateTime(base.year, base.month, day, hour24, min, 0);
        }
      }
    }

    // 3.6.5. "the day before/after [ordinal] [Month] [time]" (e.g. "the day before July 4th 8AM", "the day after April 2nd 9AM")
    const monthNames = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final dayBeforeAfterMonth = RegExp(
      r'the\s+day\s+(before|after)\s+(\d{1,2})(?:st|nd|rd|th)?\s+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final dayBeforeAfterMonthMatch = dayBeforeAfterMonth.firstMatch(trimmed);
    if (dayBeforeAfterMonthMatch != null) {
      final isBefore = dayBeforeAfterMonthMatch.group(1)!.toLowerCase() == 'before';
      final dayNum = int.parse(dayBeforeAfterMonthMatch.group(2)!);
      final monthStr = dayBeforeAfterMonthMatch.group(3)!.toLowerCase().substring(0, 3);
      final monthIdx = monthNames.indexOf(monthStr);
      if (monthIdx >= 0 && dayNum >= 1 && dayNum <= 31) {
        final m = monthIdx + 1;
        final lastDay = DateTime(now.year, m + 1, 0).day;
        final d = dayNum > lastDay ? lastDay : dayNum;
        if (_isValidDate(now.year, m, d)) {
          var dt = DateTime(now.year, m, d);
          if (dt.isBefore(today)) dt = DateTime(now.year + 1, m, d);
          // Apply "before" or "after"
          dt = isBefore ? dt.subtract(const Duration(days: 1)) : dt.add(const Duration(days: 1));
          final hStr = dayBeforeAfterMonthMatch.group(4);
          final minStr = dayBeforeAfterMonthMatch.group(5);
          final amPm = dayBeforeAfterMonthMatch.group(6)?.toLowerCase();
          final h = hStr != null ? int.parse(hStr) : 9;
          final min = minStr != null ? int.parse(minStr) : 0;
          final hour24 = _to24h(h, min, amPm);
          if (hour24 != null && _isValidTime(hour24, min, 0) && _isValidDate(dt.year, dt.month, dt.day)) {
            return DateTime(dt.year, dt.month, dt.day, hour24, min, 0);
          }
        }
      }
    }

    // 3.7. "[ordinal] [Month] [time]" (e.g. "3rd Feb 7AM", "31st January 8AM")
    final ordinalMonth = RegExp(
      r'(\d{1,2})(?:st|nd|rd|th)?\s+(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|jul(?:y)?|aug(?:ust)?|sep(?:tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final ordinalMonthMatch = ordinalMonth.firstMatch(trimmed);
    if (ordinalMonthMatch != null) {
      final dayNum = int.parse(ordinalMonthMatch.group(1)!);
      final monthStr = ordinalMonthMatch.group(2)!.toLowerCase().substring(0, 3);
      final monthIdx = monthNames.indexOf(monthStr);
      if (monthIdx >= 0 && dayNum >= 1 && dayNum <= 31) {
        final m = monthIdx + 1;
        final lastDay = DateTime(now.year, m + 1, 0).day;
        final d = dayNum > lastDay ? lastDay : dayNum;
        if (_isValidDate(now.year, m, d)) {
          var dt = DateTime(now.year, m, d);
          if (dt.isBefore(today)) dt = DateTime(now.year + 1, m, d);
          final hStr = ordinalMonthMatch.group(3);
          final minStr = ordinalMonthMatch.group(4);
          final amPm = ordinalMonthMatch.group(5)?.toLowerCase();
          final h = hStr != null ? int.parse(hStr) : 9;
          final min = minStr != null ? int.parse(minStr) : 0;
          final hour24 = _to24h(h, min, amPm);
          if (hour24 != null && _isValidTime(hour24, min, 0)) {
            return DateTime(dt.year, dt.month, dt.day, hour24, min, 0);
          }
        }
      }
    }

    // 3.7.5. "the day before/after [ordinal] [time]" (e.g. "the day after 21st 5AM")
    final dayBeforeAfterOrdinal = RegExp(
      r'the\s+day\s+(before|after)\s+(\d{1,2})(?:st|nd|rd|th)?\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final dayBeforeAfterOrdinalMatch = dayBeforeAfterOrdinal.firstMatch(trimmed);
    if (dayBeforeAfterOrdinalMatch != null) {
      final isBefore = dayBeforeAfterOrdinalMatch.group(1)!.toLowerCase() == 'before';
      final dayNum = int.parse(dayBeforeAfterOrdinalMatch.group(2)!);
      final hStr = dayBeforeAfterOrdinalMatch.group(3);
      final minStr = dayBeforeAfterOrdinalMatch.group(4);
      final amPm = dayBeforeAfterOrdinalMatch.group(5)?.toLowerCase();
      final h = hStr != null ? int.parse(hStr) : 9;
      final min = minStr != null ? int.parse(minStr) : 0;
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0) && dayNum >= 1 && dayNum <= 31) {
        // Find next occurrence of that day number
        var y = now.year;
        var m = now.month;
        var lastDay = DateTime(y, m + 1, 0).day;
        var d = dayNum > lastDay ? lastDay : dayNum;
        // If this month doesn't have that day, find next month that does
        while (dayNum > lastDay) {
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
          lastDay = DateTime(y, m + 1, 0).day;
          d = dayNum > lastDay ? lastDay : dayNum;
        }
        var dt = DateTime(y, m, d);
        // Ensure we have a future date
        while (dt.isBefore(today)) {
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
          lastDay = DateTime(y, m + 1, 0).day;
          d = dayNum > lastDay ? lastDay : dayNum;
          dt = DateTime(y, m, d);
        }
        // Apply "before" or "after"
        dt = isBefore ? dt.subtract(const Duration(days: 1)) : dt.add(const Duration(days: 1));
        if (_isValidDate(dt.year, dt.month, dt.day)) {
          return DateTime(dt.year, dt.month, dt.day, hour24, min, 0);
        }
      }
    }

    // 3.8. "[ordinal] [time]" (e.g. "31st 8AM", "10th 9AM") = next occurrence of that day in month
    final ordinalTime = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
      caseSensitive: false,
    );
    final ordinalTimeMatch = ordinalTime.firstMatch(trimmed);
    if (ordinalTimeMatch != null) {
      final dayNum = int.parse(ordinalTimeMatch.group(1)!);
      final hStr = ordinalTimeMatch.group(2);
      final minStr = ordinalTimeMatch.group(3);
      final amPm = ordinalTimeMatch.group(4)?.toLowerCase();
      final h = hStr != null ? int.parse(hStr) : 9;
      final min = minStr != null ? int.parse(minStr) : 0;
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0) && dayNum >= 1 && dayNum <= 31) {
        var y = now.year;
        var m = now.month;
        var lastDay = DateTime(y, m + 1, 0).day;
        var d = dayNum > lastDay ? lastDay : dayNum;
        // If this month doesn't have that day (e.g. 31st in Feb), find next month that does
        while (dayNum > lastDay) {
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
          lastDay = DateTime(y, m + 1, 0).day;
          d = dayNum > lastDay ? lastDay : dayNum;
        }
        var dt = DateTime(y, m, d, hour24, min, 0);
        while (dt.isBefore(now)) {
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
          lastDay = DateTime(y, m + 1, 0).day;
          d = dayNum > lastDay ? lastDay : dayNum;
          dt = DateTime(y, m, d, hour24, min, 0);
        }
        if (_isValidDate(y, m, d)) {
          return dt;
        }
      }
    }

    // 4. Time only: "3:30 PM", "14:30", "3pm", "9:00 am"
    final timeOnly = RegExp(
      r'(?:^|\s)(\d{1,2})(?::(\d{2}))?\s*(am|pm)?(?:\s|$|[,.]|\))',
      caseSensitive: false,
    );
    final timeMatch = timeOnly.firstMatch(trimmed);
    if (timeMatch != null) {
      final h = int.parse(timeMatch.group(1)!);
      final min = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      final amPm = timeMatch.group(3)?.toLowerCase();
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0)) {
        return DateTime(today.year, today.month, today.day, hour24, min, 0);
      }
    }

    // 5. Standalone time at end: "meet at 3pm" or "3pm"
    final atTime = RegExp(
      r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    final atMatch = atTime.firstMatch(trimmed);
    if (atMatch != null) {
      final h = int.parse(atMatch.group(1)!);
      final min = atMatch.group(2) != null ? int.parse(atMatch.group(2)!) : 0;
      final amPm = atMatch.group(3)!.toLowerCase();
      final hour24 = _to24h(h, min, amPm);
      if (hour24 != null && _isValidTime(hour24, min, 0)) {
        return DateTime(today.year, today.month, today.day, hour24, min, 0);
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}

int? _to24h(int h, int min, String? amPm) {
  if (amPm == null || amPm.isEmpty) {
    if (h >= 0 && h <= 23) return h;
    return null;
  }
  if (amPm == 'am') {
    if (h == 12) return 0;
    return h >= 1 && h <= 12 ? h : null;
  }
  if (amPm == 'pm') {
    if (h == 12) return 12;
    return h >= 1 && h <= 12 ? h + 12 : null;
  }
  return null;
}

bool _isValidDate(int y, int m, int d) {
  if (y < 1970 || y > 2100 || m < 1 || m > 12) return false;
  final last = DateTime(y, m + 1, 0).day;
  return d >= 1 && d <= last;
}

bool _isValidTime(int h, int m, int s) {
  return h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59;
}
