import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'profile_detail_screen.dart';
import 'onboarding_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getCurrentUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load profile: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    if (_profile == null) return;
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(existingProfile: _profile!),
      ),
    );

    // 편집 후 프로필 새로고침
    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
        ),
        body: const Center(
          child: Text('Profile not found'),
        ),
      );
    }

    // 채팅에서 이름 탭 시 나오는 프로필과 동일 형식: AppBar에 이름·나이·성별, 본문 컴팩트 레이아웃
    return Scaffold(
      body: ProfileDetailScreen(
        profile: _profile!,
        hideAppBar: false,
        currentUserProfile: _profile,
        appBarActions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEdit,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }
}
