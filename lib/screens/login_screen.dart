import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _loadingProvider;

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
      );

      if (response == false) {
        throw Exception('Social login cancelled');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingProvider = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Social login error: $e');
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
    return Scaffold(
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Text(
                      'Twingl',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
