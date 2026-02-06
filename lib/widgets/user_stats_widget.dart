import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme/app_theme.dart';

/// Activity stats widget bound to [UserModel] real data.
/// Displays profile views, fans, and incoming/outgoing request counts.
class UserStatsWidget extends StatelessWidget {
  const UserStatsWidget({
    super.key,
    required this.user,
    this.showTitle = true,
    this.wrapInCard = true,
  });

  final UserModel user;
  /// When false, only the stats rows are shown (for use inside expandable section).
  final bool showTitle;
  /// When false, no Card wrapper (for use inside expandable section).
  final bool wrapInCard;

  static int _intFrom(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final stats = user.stats ?? {};
    final views = _intFrom(stats['profileViewCount']);
    final fans = _intFrom(stats['favoriteCount']);

    final incoming = stats['incomingRequests'] is Map ? stats['incomingRequests'] as Map : null;
    final inAccepted = _intFrom(incoming?['accepted']);
    final inTotal = _intFrom(incoming?['total']);

    final outgoing = stats['outgoingRequests'] is Map ? stats['outgoingRequests'] as Map : null;
    final outAccepted = _intFrom(outgoing?['accepted']);
    final outTotal = _intFrom(outgoing?['total']);

    final scheme = Theme.of(context).colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          Text(
            'My Activity Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
        ],
        // Row 1: Views & Liked (aligned with row 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _vanityItem(context, icon: Icons.visibility, color: Colors.blue, count: views, label: 'Views'),
            ),
            Expanded(
              child: _vanityItem(context, icon: Icons.thumb_up, color: AppTheme.twinglGreen, count: fans, label: 'Liked'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Row 2: Requests & Requesteds
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _activityColumn(
                context,
                header: 'Requests',
                accepted: inAccepted,
                total: inTotal,
              ),
            ),
            Expanded(
              child: _activityColumn(
                context,
                header: 'Requesteds',
                accepted: outAccepted,
                total: outTotal,
              ),
            ),
          ],
        ),
      ],
    );

    if (!wrapInCard) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: content,
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _vanityItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _activityColumn(
    BuildContext context, {
    required String header,
    required int accepted,
    required int total,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          header,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.3,
                ),
            children: [
              TextSpan(
                text: '$accepted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                ),
              ),
              TextSpan(
                text: ' / $total',
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
