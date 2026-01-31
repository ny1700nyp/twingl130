import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/public_profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oibboowecbxvjmookwtd.supabase.co',
    anonKey: 'sb_publishable_SYXxaO7zPzUsgarNzSqCgA_pdhR9ZIj',
  );

  // Notification service (used by chat/calendar flows)
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  NotificationService().setNavigatorKey(navigatorKey);

  runApp(const TwinglApp());
}

class TwinglApp extends StatelessWidget {
  const TwinglApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Twingl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OnboardingScreen(
            initialUserType: args?['userType'] as String?,
          );
        },
        '/home': (context) => const MainScreen(),
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] as String?;
          if (userId == null || userId.isEmpty) {
            return const Scaffold(
              body: SafeArea(child: Center(child: Text('Invalid profile link'))),
            );
          }
          return PublicProfileScreen(userId: userId);
        },
      },
      initialRoute: '/',
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // Auth change listener
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        if (!mounted) return;
        setState(() => _showSplash = false);
        _checkAuthStatus();
      } else if (event == AuthChangeEvent.signedOut) {
        if (!mounted) return;
        setState(() => _showSplash = false);
        SupabaseService.clearInMemoryCaches();
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _showSplash = false);
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Hydrate device caches first for instant rendering.
      await SupabaseService.hydrateCachesFromDisk(user.id);

      // Profile check (cache-first)
      final profile = await SupabaseService.getCurrentUserProfileCached(user.id);

      if (!mounted) return;
      setState(() => _showSplash = false);

      if (profile == null) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _showSplash = false);
      Navigator.of(context).pushReplacementNamed('/login');
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash && _isChecking) {
      return const SplashScreen();
    }
    return const Scaffold(body: SizedBox.shrink());
  }
}

