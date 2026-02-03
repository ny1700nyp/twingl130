import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

/// Shows a custom dialog explaining the given identity (student, tutor, twiner).
void showIdentityDialog(BuildContext context, String type) {
  final t = (type.trim().toLowerCase());
  Color headerColor;
  String letter;
  String title;
  String description;
  switch (t) {
    case 'student':
      headerColor = AppTheme.twinglMint;
      letter = 'S';
      title = 'The Learner';
      description =
          'Focus on your growth. Define your goals and find the perfect mentors nearby or globally.';
      break;
    case 'tutor':
      headerColor = AppTheme.twinglPurple;
      letter = 'T';
      title = 'The Guide';
      description =
          'Share your expertise. Turn your talents into value by helping others achieve their dreams.';
      break;
    case 'twiner':
      headerColor = AppTheme.twinglYellow;
      letter = 'TW';
      title = 'The Connector';
      description =
          'The ultimate Twingl experience. You teach what you know and learn what you love. You are the heart of our community.';
      break;
    default:
      return;
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            color: headerColor,
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  height: 1,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _converting = false;

  /// user_type·추가 정보는 Save 버튼을 눌렀을 때만 DB에 저장. 여기서는 온보딩만 열고 DB 변경 없음.
  Future<void> _convertToTwinerAndOpenOnboarding(
    Map<String, dynamic> profile,
    String userId,
  ) async {
    if (_converting) return;
    setState(() => _converting = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            existingProfile: Map<String, dynamic>.from(profile),
            initialUserType: 'twiner',
          ),
        ),
      );
      if (!mounted) return;
      await SupabaseService.refreshCurrentUserProfileCache(userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start conversion: $e')),
      );
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('More'),
      ),
      body: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: SupabaseService.currentUserProfileCache,
        builder: (context, profile, _) {
          final userType =
              (profile?['user_type'] as String?)?.trim().toLowerCase() ?? '';
          final isTutor = userType == 'tutor';
          final isStudent = userType == 'student';
          final showTwinerCard = isTutor || isStudent;
          final user = Supabase.instance.client.auth.currentUser;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            children: [
              // User Badge Guide (Twingl Identity)
              const _BadgeGuideCard(),
              const SizedBox(height: 24),

              // Become a Tutor/Student too (Twingl Identity 다음 배치)
              if (showTwinerCard) ...[
                _TwinerConversionCard(
                  isTutor: isTutor,
                  converting: _converting,
                  onUnlock: user != null && profile != null
                      ? () => _convertToTwinerAndOpenOnboarding(
                            profile,
                            user.id,
                          )
                      : null,
                ),
                const SizedBox(height: 24),
              ],

              // Lesson Space Finder
              const _LessonSpaceFinderCard(),
            ],
          );
        },
      ),
    );
  }
}

class _TwinerConversionCard extends StatelessWidget {
  const _TwinerConversionCard({
    required this.isTutor,
    required this.converting,
    required this.onUnlock,
  });

  final bool isTutor;
  final bool converting;
  final VoidCallback? onUnlock;

  /// 추가될 search — 변환 후 홈에 표시될 검색 섹션 미리보기 (버튼은 비동작, 텍스트만 표시).
  Widget _previewRow(BuildContext context, {required IconData icon, required String title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.visible,
              softWrap: true,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headline =
        isTutor ? 'Become a Student too' : 'Become a Tutor too';
    final subtext = isTutor
        ? 'Great teachers never stop learning. Expand your perspective by achieving new goals.'
        : 'Teaching is the best way to master your skills. Share your talent with neighbors.';
    final buttonLabel =
        isTutor ? 'Unlock Student Mode' : 'Unlock Tutor Mode';

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
              headline,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtext,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.85),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will get the Twiner badge.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.twinglYellow,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: converting || onUnlock == null ? null : onUnlock,
                icon: converting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isTutor ? Icons.school_outlined : Icons.groups_outlined),
                label: Text(converting ? 'Starting…' : buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            // 추가될 search — 변환 후 홈에 표시될 검색 섹션 미리보기 (비동작)
            const SizedBox(height: 16),
            if (isTutor) ...[
              _previewRow(context, icon: Icons.search, title: 'Meet Tutors in your area'),
              const SizedBox(height: 10),
              _previewRow(context, icon: Icons.auto_awesome_outlined, title: 'The Perfect Tutors, Anywhere'),
            ] else ...[
              _previewRow(context, icon: Icons.groups_outlined, title: 'Other Tutors in the area'),
              const SizedBox(height: 10),
              _previewRow(context, icon: Icons.school_outlined, title: 'Student Candidates in the area'),
            ],
          ],
        ),
      ),
    );
  }
}

/// User Badge Guide: Twingl Identity – S, T, TW badges with same card style as Lesson Space Finder.
class _BadgeGuideCard extends StatelessWidget {
  const _BadgeGuideCard();

  static const double _badgeSize = 48;

  Widget _badge({
    required BuildContext context,
    required Color color,
    required String letter,
    required String label,
    bool highlight = false,
    VoidCallback? onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: _badgeSize,
              height: _badgeSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: highlight
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: letter.length > 1 ? 14 : 22,
                  height: 1,
                ),
              ),
            ),
            if (highlight)
              Positioned(
                top: -2,
                right: -2,
                child: Icon(
                  Icons.star,
                  size: 16,
                  color: AppTheme.twinglYellow,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_badgeSize),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Twingl Identity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Learn, Share, and Connect.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _badge(
                  context: context,
                  color: AppTheme.twinglMint,
                  letter: 'S',
                  label: 'Student',
                  onTap: () => showIdentityDialog(context, 'student'),
                ),
                _badge(
                  context: context,
                  color: AppTheme.twinglPurple,
                  letter: 'T',
                  label: 'Tutor',
                  onTap: () => showIdentityDialog(context, 'tutor'),
                ),
                _badge(
                  context: context,
                  color: AppTheme.twinglYellow,
                  letter: 'TW',
                  label: 'Twiner',
                  highlight: true,
                  onTap: () => showIdentityDialog(context, 'twiner'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lesson Space Finder: 2x2 grid of links to library, school, studio, meeting room platforms.
class _LessonSpaceFinderCard extends StatelessWidget {
  const _LessonSpaceFinderCard();

  static const double _gridSpacing = 12;
  static const double _gridGap = 12;

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link.')),
        );
      }
    }
  }

  Widget _gridTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String url,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withOpacity(0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openUrl(context, url),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Lesson Space Finder',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: _gridSpacing,
              crossAxisSpacing: _gridGap,
              childAspectRatio: 0.95,
              children: [
                _gridTile(
                  context,
                  icon: Icons.local_library,
                  iconColor: Colors.blue,
                  label: 'Public Libraries',
                  url: 'https://www.google.com/search?q=library+room+reservation',
                ),
                _gridTile(
                  context,
                  icon: Icons.school,
                  iconColor: AppTheme.twinglGreen,
                  label: 'School Facilities',
                  url: 'https://www.facilitron.com/',
                ),
                _gridTile(
                  context,
                  icon: Icons.camera_indoor,
                  iconColor: Colors.red.shade400,
                  label: 'Creative Studios',
                  url: 'https://www.peerspace.com/',
                ),
                _gridTile(
                  context,
                  icon: Icons.meeting_room,
                  iconColor: Colors.indigo.shade700,
                  label: 'Meeting Rooms',
                  url: 'https://liquidspace.com/',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
