import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_navigation.dart' show navigatorKey;
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/twingl_wordmark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _loadingProvider;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // 로그아웃 후 재로그인: AuthWrapper가 스택에서 제거된 상태에서 세션 생기면
    // 여기서 로딩을 끄고 홈으로 보냄 (AuthWrapper 리스너는 이미 dispose됨)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event != AuthChangeEvent.signedIn || data.session == null) return;
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
        _navigateAfterSignIn(data.session!.user.id);
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateAfterSignIn(String userId) async {
    try {
      await SupabaseService.hydrateCachesFromDisk(userId);
      final profile = await SupabaseService.getCurrentUserProfileCached(userId);
      if (!mounted) return;
      if (profile == null) {
        navigatorKey.currentState?.pushReplacementNamed('/onboarding');
      } else {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        navigatorKey.currentState?.pushReplacementNamed('/');
      }
    }
  }

  Future<void> _signInAnonymouslyAndGoOnboarding() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadingProvider = 'anonymous';
    });

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        await client.auth.signOut();
      }
      await client.auth.signInAnonymously();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anonymous login failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  Future<void> _signInWithProvider(OAuthProvider provider) async {
    setState(() {
      _isLoading = true;
      _loadingProvider = provider.name;
    });

    try {
      // 웹과 모바일에서 다른 redirectTo 사용
      String? redirectTo;
      LaunchMode launchMode;
      
      if (kIsWeb) {
        // 웹의 경우 현재 페이지의 전체 URL 사용 (쿼리 파라미터 포함)
        redirectTo = Uri.base.toString();
        launchMode = LaunchMode.inAppWebView;
      } else {
        // 모바일의 경우 deep link 사용
        redirectTo = 'io.supabase.gurutown://login-callback/';
        launchMode = LaunchMode.externalApplication;
      }

      final response = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: redirectTo,
        authScreenLaunchMode: launchMode,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Opening login window timed out. Check your network.',
          );
        },
      );

      if (response == false) {
        throw Exception('Social login cancelled');
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
      });

      if (mounted) {
        final isTimeout = e is TimeoutException;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTimeout
                  ? '네트워크가 지연되고 있습니다. 잠시 후 다시 시도해 주세요.'
                  : 'Login failed: $e',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // 상세 로그 (디버깅용)
      print('Social login error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack: $stackTrace');
    }
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: InkWell(
                  onTap: _isLoading ? null : _signInAnonymouslyAndGoOnboarding,
                  child: const TwinglWordmark(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with social login',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildSocialButton(
                label: 'Sign in with Google',
                icon: Icons.g_mobiledata,
                color: const Color(0xFF4285F4),
                onPressed: () => _signInWithProvider(OAuthProvider.google),
                isLoading: _isLoading && _loadingProvider == 'google',
              ),
              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
