import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Distance formatting used across the app.
///
/// Privacy-friendly rules (rounded to 1km units):
/// - Round to nearest km (no decimals)
/// - 0km after rounding => localized "Super close"
/// - Otherwise => localized "{N} km away"
String formatDistanceMeters(BuildContext context, double distanceMeters) {
  final l10n = AppLocalizations.of(context);
  if (distanceMeters.isNaN || !distanceMeters.isFinite) return '—';
  if (distanceMeters < 0) distanceMeters = 0;
  final km = (distanceMeters / 1000.0).round();
  if (km <= 0) return l10n?.superClose ?? 'Super close';
  return l10n?.kmAway(km) ?? '$km km away';
}
