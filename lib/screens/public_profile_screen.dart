import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'profile_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? currentUserProfile;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.currentUserProfile,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _currentUserProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentUserProfile = widget.currentUserProfile ?? SupabaseService.currentUserProfileCache.value;
    _loadProfile();
    _loadCurrentUserProfileIfNeeded();
  }

  Future<void> _loadCurrentUserProfileIfNeeded() async {
    if (_currentUserProfile != null) return;
    final user = SupabaseService.supabase.auth.currentUser;
    if (user == null) return;
    try {
      final prof = await SupabaseService.getCurrentUserProfileCached(user.id);
      if (!mounted) return;
      setState(() => _currentUserProfile = prof);
    } catch (_) {
      // ignore (profile will just render without highlights)
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getPublicProfile(widget.userId);
      setState(() {
        _profile = profile;
        _isLoading = false;
        if (profile == null) {
          _error = 'Profile not found';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const SizedBox.shrink(),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const SizedBox.shrink(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Profile not found',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return ProfileDetailScreen(
      profile: _profile!,
      hideAppBar: false,
      // If signed-in, provide current user profile so matching chips can highlight.
      currentUserProfile: _currentUserProfile,
    );
  }
}
