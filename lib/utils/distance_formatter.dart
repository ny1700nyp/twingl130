/// Distance formatting used across the app.
///
/// Privacy-friendly rules (rounded to 1km units):
/// - Round to nearest km (no decimals)
/// - 0km after rounding => "Super close"
/// - Otherwise => "{N} km away"
String formatDistanceMeters(double distanceMeters) {
  if (distanceMeters.isNaN || !distanceMeters.isFinite) return '—';
  if (distanceMeters < 0) distanceMeters = 0;
  final km = (distanceMeters / 1000.0).round();
  if (km <= 0) return 'Super close';
  return '$km km away';
}

