import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_navigation.dart' show navigatorKey;
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'general_settings_screen.dart';
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
                RichText(
                  text: TextSpan(
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                    children: AppTheme.textSpansWithTwinglHighlight(
                      description,
                      baseStyle: Theme.of(ctx)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.black87,
                                height: 1.4,
                              ) ??
                          const TextStyle(color: Colors.black87, height: 1.4),
                    ),
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
  bool _expandWhatIsTwingl = false;
  bool _expandPaymentGuide = false;
  bool _expandTwiner = false;
  bool _expandLessonSpace = false;

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
              // About US (제일 위)
              Text(
                'About US',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _AboutUsQuoteCard(
                expandWhatIsTwingl: _expandWhatIsTwingl,
                onToggleWhatIsTwingl: () =>
                    setState(() => _expandWhatIsTwingl = !_expandWhatIsTwingl),
                onTapLetterFromTwingl: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment guide
              Text(
                'Payment guide',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _PaymentGuideQuoteCard(
                expanded: _expandPaymentGuide,
                onTap: () => setState(() => _expandPaymentGuide = !_expandPaymentGuide),
              ),
              const SizedBox(height: 24),

              // Offer (Become a Tutor/Student too)
              if (showTwinerCard) ...[
                Text(
                  'Offer',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                _OfferQuoteCard(
                  isTutor: isTutor,
                  expanded: _expandTwiner,
                  onTap: () => setState(() => _expandTwiner = !_expandTwiner),
                  converting: _converting,
                  onUnlock: user != null && profile != null
                      ? () => _convertToTwinerAndOpenOnboarding(
                            Map<String, dynamic>.from(profile),
                            user.id,
                          )
                      : null,
                ),
                const SizedBox(height: 24),
              ],

              // Useful links
              Text(
                'Useful links',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _ExpandableSectionCard(
                title: 'Lesson Space Finder',
                expanded: _expandLessonSpace,
                onTap: () => setState(() => _expandLessonSpace = !_expandLessonSpace),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _LessonSpaceFinderCardContent(),
                ),
              ),
              const SizedBox(height: 24),

              // Notifications
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: _NotificationsCardContent(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account
              Text(
                'Account',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const _AccountCardContent(),
                ),
              ),
              const SizedBox(height: 24),

              // Support, Logout
              _GeneralSettingsSection(user: user),
            ],
          );
        },
      ),
    );
  }
}

/// About US card with Quote(SparkCard)-style gradient background.
class _AboutUsQuoteCard extends StatelessWidget {
  const _AboutUsQuoteCard({
    required this.expandWhatIsTwingl,
    required this.onToggleWhatIsTwingl,
    required this.onTapLetterFromTwingl,
  });

  final bool expandWhatIsTwingl;
  final VoidCallback onToggleWhatIsTwingl;
  final VoidCallback onTapLetterFromTwingl;

  static const Color _white = Colors.white;

  static const double cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.twinglPurple.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.twinglPurple,
            AppTheme.twinglMint,
            AppTheme.twinglYellow,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -8,
            right: 4,
            child: Opacity(
              opacity: 0.10,
              child: Text(
                '"',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 80,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: _white,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onToggleWhatIsTwingl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: _white.withAlpha(250),
                                ),
                            children: [
                              const TextSpan(text: 'What is '),
                              TextSpan(
                                text: 'Twingl',
                                style: AppTheme.twinglStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ).copyWith(color: _white),
                              ),
                              const TextSpan(text: ' ?'),
                            ],
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: expandWhatIsTwingl ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: _white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: expandWhatIsTwingl
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _WhatIsTwinglContent(useWhiteText: true),
                      )
                    : const SizedBox.shrink(),
              ),
              ListTile(
                title: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _white.withAlpha(250),
                        ),
                    children: [
                      const TextSpan(text: 'Letter from '),
                      TextSpan(
                        text: 'Twingl',
                        style: AppTheme.twinglStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ).copyWith(color: _white),
                      ),
                    ],
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: _white.withAlpha(230)),
                onTap: onTapLetterFromTwingl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Payment guide card with Quote-style gradient (same content as chat payment notice).
class _PaymentGuideQuoteCard extends StatelessWidget {
  const _PaymentGuideQuoteCard({
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  static const List<Color> _quoteGradient = [AppTheme.twinglMint, AppTheme.twinglPurple];
  static const double cardRadius = 16;

  static const String _content =
      'Twingl connects you with neighbors, but we don\'t handle payments directly. '
      'This keeps our service free and puts 100% of the fee in your tutor\'s pocket!\n\n'
      'Please agree on a method that works for both of you, such as:\n'
      '📱 Venmo / Zelle / PayPal\n'
      '💵 Cash\n'
      '☕️ Coffee or Meal (for casual sessions)\n\n'
      'Note: For safety, we recommend paying after meeting in person.\n\n'
      '💡 Tip: For online lessons, consider paying via PayPal for buyer protection, or use the 50/50 payment method.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: _quoteGradient.first.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _quoteGradient,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'How do I pay for lessons?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(250),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.white.withAlpha(250),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        _content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(250),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offer card (Become a Tutor/Student too) with Quote-style gradient.
/// Become a Tutor too: mint → gold. Become a Student too: purple → gold.
class _OfferQuoteCard extends StatelessWidget {
  const _OfferQuoteCard({
    required this.isTutor,
    required this.expanded,
    required this.onTap,
    required this.converting,
    required this.onUnlock,
  });

  final bool isTutor;
  final bool expanded;
  final VoidCallback onTap;
  final bool converting;
  final VoidCallback? onUnlock;

  static const Color _white = Colors.white;
  static const Color _gold = Color(0xFFF59E0B); // twinglYellow
  static const double cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    final title = isTutor ? 'Become a Student too' : 'Become a Tutor too';
    final gradientColors = isTutor
        ? [AppTheme.twinglPurple, _gold]
        : [AppTheme.twinglMint, _gold];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: _white.withAlpha(250),
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: _white.withAlpha(230),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _TwinerConversionCardContent(
                      isTutor: isTutor,
                      converting: converting,
                      onUnlock: onUnlock,
                      useWhiteText: true,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Content for "What is Twingl?" with inline Student/Tutor/Twiner badges.
class _WhatIsTwinglContent extends StatelessWidget {
  const _WhatIsTwinglContent({this.useWhiteText = false});

  final bool useWhiteText;
  static const double _inlineBadgeSize = 14;

  Widget _inlineBadge(Color color, String letter) {
    return Container(
      width: _inlineBadgeSize,
      height: _inlineBadgeSize,
      margin: const EdgeInsets.only(left: 2, right: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: letter.length > 1 ? 7 : 9,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5) ??
        const TextStyle();
    final baseStyle = useWhiteText
        ? style.copyWith(color: Colors.white.withAlpha(250))
        : style.copyWith(color: Theme.of(context).colorScheme.onSurface);
    final twinglStyle = useWhiteText
        ? AppTheme.twinglStyle(
            fontSize: baseStyle.fontSize,
            fontWeight: baseStyle.fontWeight,
          ).copyWith(color: Colors.white)
        : AppTheme.twinglStyle(
            fontSize: baseStyle.fontSize,
            fontWeight: baseStyle.fontWeight,
          );
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: "The name "),
          TextSpan(text: "Twingl", style: twinglStyle),
          TextSpan(
            text: " is a blend of 'Twin' and 'Mingle', echoing the word 'Twinkle'.\n\n",
          ),
          const TextSpan(
            text: "We believe everyone has Twin",
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _inlineBadge(AppTheme.twinglYellow, 'TW'),
          ),
          const TextSpan(
            text: " potentials: the curiosity of a student",
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _inlineBadge(AppTheme.twinglMint, 'S'),
          ),
          const TextSpan(
            text: " and the wisdom of a tutor",
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _inlineBadge(AppTheme.twinglPurple, 'T'),
          ),
          const TextSpan(
            text: ". "
            "When we come out to Mingle with our neighbors, sharing what we know and learning what we love, we spark a light in each other.\n\n"
            "That is when we truly Twinkle—growing brighter, together.",
          ),
        ],
      ),
    );
  }
}

/// Card with a tappable title that expands/collapses the child with slide animation.
class _ExpandableSectionCard extends StatelessWidget {
  const _ExpandableSectionCard({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  static const double cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? child
                  : const SizedBox.shrink(),
            ),
          ],
        ),
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
              _previewRow(context, icon: Icons.groups_outlined, title: 'Fellow tutors in the area'),
              const SizedBox(height: 10),
              _previewRow(context, icon: Icons.school_outlined, title: 'Student Candidates in the area'),
            ],
          ],
        ),
      ),
    );
  }
}

/// Content only (for expandable): body of Twiner conversion without title.
class _TwinerConversionCardContent extends StatelessWidget {
  const _TwinerConversionCardContent({
    required this.isTutor,
    required this.converting,
    required this.onUnlock,
    this.useWhiteText = false,
  });

  final bool isTutor;
  final bool converting;
  final VoidCallback? onUnlock;
  final bool useWhiteText;

  Widget _previewRow(BuildContext context, {required IconData icon, required String title}) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = useWhiteText ? Colors.white.withAlpha(30) : scheme.surfaceContainerHighest;
    final iconColor = useWhiteText ? Colors.white : scheme.primary;
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: useWhiteText ? Colors.white.withAlpha(250) : null,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (useWhiteText ? Colors.white : scheme.primary).withAlpha(useWhiteText ? 40 : 22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.visible,
              softWrap: true,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtext = isTutor
        ? 'Great teachers never stop learning. Expand your perspective by achieving new goals.'
        : 'Teaching is the best way to master your skills. Share your talent with neighbors.';
    final buttonLabel = isTutor ? 'Unlock Student Mode' : 'Unlock Tutor Mode';
    final textColor = useWhiteText ? Colors.white.withAlpha(250) : Theme.of(context).colorScheme.onSurface.withOpacity(0.85);
    final badgeColor = useWhiteText ? const Color(0xFFFDE68A) : AppTheme.twinglYellow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          subtext,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'You will get the Twiner badge.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: badgeColor,
                height: 1.3,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: converting || onUnlock == null ? null : onUnlock,
            icon: converting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: useWhiteText ? Colors.white : null,
                    ),
                  )
                : Icon(isTutor ? Icons.school_outlined : Icons.groups_outlined),
            label: Text(converting ? 'Starting…' : buttonLabel),
            style: FilledButton.styleFrom(
              backgroundColor: useWhiteText ? Colors.white : Theme.of(context).colorScheme.primary,
              foregroundColor: useWhiteText ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isTutor) ...[
          _previewRow(context, icon: Icons.search, title: 'Meet Tutors in your area'),
          const SizedBox(height: 10),
          _previewRow(context, icon: Icons.auto_awesome_outlined, title: 'The Perfect Tutors, Anywhere'),
        ] else ...[
          _previewRow(context, icon: Icons.groups_outlined, title: 'Fellow tutors in the area'),
          const SizedBox(height: 10),
          _previewRow(context, icon: Icons.school_outlined, title: 'Student Candidates in the area'),
        ],
      ],
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

/// Content only (for expandable): subtitle + badge row.
class _BadgeGuideCardContent extends StatelessWidget {
  const _BadgeGuideCardContent();

  static const double _badgeSize = 48;

  Widget _badge(
    BuildContext context, {
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
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)]
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
                child: Icon(Icons.star, size: 16, color: AppTheme.twinglYellow),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            _badge(context, color: AppTheme.twinglMint, letter: 'S', label: 'Student',
                onTap: () => showIdentityDialog(context, 'student')),
            _badge(context, color: AppTheme.twinglPurple, letter: 'T', label: 'Tutor',
                onTap: () => showIdentityDialog(context, 'tutor')),
            _badge(context, color: AppTheme.twinglYellow, letter: 'TW', label: 'Twiner', highlight: true,
                onTap: () => showIdentityDialog(context, 'twiner')),
          ],
        ),
      ],
    );
  }
}

/// Account content: Verification, Language.
class _AccountCardContent extends StatelessWidget {
  const _AccountCardContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Verification'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications content: Chat messages on/off toggle.
class _NotificationsCardContent extends StatelessWidget {
  const _NotificationsCardContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ValueListenableBuilder<bool>(
        valueListenable: NotificationService().chatNotificationsEnabled,
        builder: (context, enabled, _) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat messages'),
            subtitle: Text(
              enabled ? 'Get notified when you receive new messages' : 'Notifications off',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            trailing: Switch(
              value: enabled,
              onChanged: (v) {
                NotificationService().setChatNotificationsEnabled(v);
              },
            ),
            onTap: () {
              NotificationService().setChatNotificationsEnabled(!enabled);
            },
          );
        },
      ),
    );
  }
}

/// General Settings: Support, Logout.
class _GeneralSettingsSection extends StatelessWidget {
  const _GeneralSettingsSection({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Support',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Log out',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: user == null
                  ? null
                  : () async {
                      await Supabase.instance.client.auth.signOut();
                      SupabaseService.clearInMemoryCaches();
                      if (!context.mounted) return;
                      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
                    },
            ),
          ),
        ),
      ],
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

/// Content only (for expandable): grid of lesson space links.
class _LessonSpaceFinderCardContent extends StatelessWidget {
  const _LessonSpaceFinderCardContent();

  static const double _gridSpacing = 6;
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: iconColor),
              const SizedBox(height: 6),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: _gridSpacing,
      crossAxisSpacing: _gridGap,
      childAspectRatio: 1.15,
      children: [
        _gridTile(context, icon: Icons.local_library, iconColor: Colors.blue,
            label: 'Public Libraries', url: 'https://www.google.com/search?q=library+room+reservation'),
        _gridTile(context, icon: Icons.school, iconColor: AppTheme.twinglGreen,
            label: 'School Facilities', url: 'https://www.facilitron.com/'),
        _gridTile(context, icon: Icons.camera_indoor, iconColor: Colors.red.shade400,
            label: 'Creative Studios', url: 'https://www.peerspace.com/'),
        _gridTile(context, icon: Icons.meeting_room, iconColor: Colors.indigo.shade700,
            label: 'Meeting Rooms', url: 'https://liquidspace.com/'),
      ],
    );
  }
}
