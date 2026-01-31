/// Time utilities for consistent behavior across the app.
///
/// Rule:
/// - Store timestamps to DB in UTC ISO-8601.
/// - Display timestamps in local (system) time.
class TimeUtils {
  const TimeUtils._();

  static DateTime nowLocal() => DateTime.now();

  static DateTime nowUtc() => DateTime.now().toUtc();

  static String nowUtcIso() => nowUtc().toIso8601String();

  static String toUtcIso(DateTime dt) => dt.toUtc().toIso8601String();

  static DateTime? tryParseIso(String? iso) {
    final s = (iso ?? '').trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static DateTime? tryParseIsoToLocal(String? iso) => tryParseIso(iso)?.toLocal();
}

