import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme/app_theme.dart';

/// Activity stats widget bound to [UserModel] real data.
/// Displays profile views, fans, and incoming/outgoing request counts.
class UserStatsWidget extends StatelessWidget {
  const UserStatsWidget({super.key, required this.user});

  final UserModel user;

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
    final in_accepted = _intFrom(incoming?['accepted']);
    final in_total = _intFrom(incoming?['total']);

    final outgoing = stats['outgoingRequests'] is Map ? stats['outgoingRequests'] as Map : null;
    final out_accepted = _intFrom(outgoing?['accepted']);
    final out_total = _intFrom(outgoing?['total']);

    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'My Activity Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          // Row 1: Popularity (Vanity)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _vanityItem(context, icon: Icons.visibility, color: Colors.blue, count: views, label: 'Views'),
              _vanityItem(context, icon: Icons.favorite, color: Colors.red, count: fans, label: 'Fans'),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2: Activity (Teaching vs Learning)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _activityColumn(
                  context,
                  header: 'Requests Received',
                  accepted: in_accepted,
                  total: in_total,
                ),
              ),
              Expanded(
                child: _activityColumn(
                  context,
                  header: 'Requests Sent',
                  accepted: out_accepted,
                  total: out_total,
                ),
              ),
            ],
          ),
        ],
        ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
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
