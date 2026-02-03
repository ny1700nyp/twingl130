import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Avatar with a same-size circular badge to its right.
/// Badge colors match More > Twingl Identity: S (twinglMint), T (twinglPurple), TW (twinglYellow).
class AvatarWithTypeBadge extends StatelessWidget {
  const AvatarWithTypeBadge({
    super.key,
    required this.radius,
    this.backgroundImage,
    this.backgroundColor,
    this.userType,
  });

  final double radius;
  final ImageProvider? backgroundImage;
  final Color? backgroundColor;
  /// 'tutor' | 'student' | 'twiner' (case-insensitive). Null/empty → no badge.
  final String? userType;

  static Color? _colorForUserType(String? type) {
    final t = (type ?? '').trim().toLowerCase();
    if (t == 'tutor') return AppTheme.twinglPurple;
    if (t == 'student') return AppTheme.twinglMint;
    if (t == 'twiner') return AppTheme.twinglYellow;
    return null;
  }

  static String? _labelForUserType(String? type) {
    final t = (type ?? '').trim().toLowerCase();
    if (t == 'tutor') return 'T';
    if (t == 'student') return 'S';
    if (t == 'twiner') return 'TW';
    return null;
  }

  Widget? _buildBadge() {
    final color = _colorForUserType(userType);
    final label = _labelForUserType(userType);
    if (color == null || label == null) return null;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * (label.length > 1 ? 0.65 : 0.85),
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badge = _buildBadge();
    final bg = backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    if (badge == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: backgroundImage,
        child: backgroundImage == null ? const Icon(Icons.person) : null,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: backgroundImage,
          child: backgroundImage == null ? const Icon(Icons.person) : null,
        ),
        SizedBox(width: radius * 0.4),
        badge,
      ],
    );
  }
}
