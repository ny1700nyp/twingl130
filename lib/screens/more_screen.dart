import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'edit_trainers_screen.dart';
import 'general_settings_screen.dart';
import 'my_profile_screen.dart';
import 'onboarding_screen.dart';

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

  Future<void> _onSelectMore(String value) async {
    if (!mounted) return;
    if (value == 'my_profile') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyProfileScreen()),
      );
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.refreshCurrentUserProfileCache(user.id);
      }
    } else if (value == 'edit_trainers') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EditTrainersScreen()),
      );
    } else if (value == 'general_settings') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()),
      );
    } else if (value == 'logout') {
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
      SupabaseService.clearInMemoryCaches();
      if (!mounted) return;
      nav.pushReplacementNamed('/login');
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
              // Twiner Conversion card (Tutor or Student only)
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

              // My Profile
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onSelectMore('my_profile'),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Edit my Favorite'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onSelectMore('edit_trainers'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('General Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onSelectMore('general_settings'),
              ),
              const Divider(height: 24),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Log out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () => _onSelectMore('logout'),
              ),
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
        isTutor ? 'Become a Student too.' : 'Become a Tutor too.';
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
                  backgroundColor: AppTheme.twinglGreen,
                  foregroundColor: Colors.white,
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
