import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_navigation.dart' show navigatorKey;
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/login_screen.dart';
import 'services/fcm_service.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/public_profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app orientation to portrait only.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  // Firebase (for FCM push notifications) - needs google-services.json / GoogleService-Info.plist
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await FcmService().initialize();
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }

  await Supabase.initialize(
    url: 'https://oibboowecbxvjmookwtd.supabase.co',
    anonKey: 'sb_publishable_SYXxaO7zPzUsgarNzSqCgA_pdhR9ZIj',
  );

  // 모바일 콜드 스타트: 딥링크로 앱이 켜졌을 때 초기 URI에서 세션 복구 시도
  if (!kIsWeb) {
    try {
      final appLinks = AppLinks();
      final uri = await appLinks.getInitialLink();
      if (uri != null &&
          uri.host == 'login-callback' &&
          (uri.queryParameters.containsKey('code') ||
              uri.queryParameters.containsKey('error'))) {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        debugPrint('Supabase: initial URI session exchange succeeded');
      }
    } catch (e, st) {
      debugPrint('Supabase: initial URI session exchange failed: $e');
      debugPrint('Stack: $st');
    }
  }

  // Notification service: set key for deep links; init & permissions deferred so first paint is not blocked.
  NotificationService().setNavigatorKey(navigatorKey);

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final provider = LocaleProvider();
        provider.fetchLocale();
        return provider;
      },
      child: const TwinglApp(),
    ),
  );
}

class TwinglApp extends StatelessWidget {
  const TwinglApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Twingl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) {
        if (locale == null) return null;
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('en');
      },
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
            return Scaffold(
              body: SafeArea(child: Center(child: Text(AppLocalizations.of(context)!.invalidProfileLink))),
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

    // Defer notification init so first paint is not blocked (runs in parallel with auth check).
    Future(() async {
      await NotificationService().initialize();
      await NotificationService().requestPermissions();
    });

    // Auth change listener (navigatorKey 사용: 로그아웃 후 /login으로 가면 AuthWrapper가 dispose되므로 context 대신 사용)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      debugPrint('Auth event: $event, hasSession: ${session != null}');

      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('Auth: signed in, redirecting to app');
        if (!mounted) return;
        setState(() => _showSplash = false);
        FcmService().registerToken(session.user.id);
        _checkAuthStatus();
      } else if (event == AuthChangeEvent.signedOut) {
        if (!mounted) return;
        setState(() => _showSplash = false);
        FcmService().unregisterToken();
        SupabaseService.clearInMemoryCaches();
        navigatorKey.currentState?.pushReplacementNamed('/login');
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
        navigatorKey.currentState?.pushReplacementNamed('/login');
        return;
      }

      // Fast path: if profile exists on disk, show home immediately and hydrate the rest in background.
      final diskProfile = await SupabaseService.loadProfileFromDiskOnly(user.id);
      if (diskProfile != null) {
        SupabaseService.setCurrentUserProfileFromDisk(user.id, diskProfile);
        if (!mounted) return;
        setState(() => _showSplash = false);
        navigatorKey.currentState?.pushReplacementNamed('/home');
        Future.microtask(() => SupabaseService.hydrateCachesFromDisk(user.id));
        Future.microtask(() => SupabaseService.refreshBootstrapCachesIfChanged(user.id));
        Future.microtask(() => FcmService().registerToken(user.id));
        return;
      }

      // No profile on disk: full hydrate then profile fetch (e.g. first install or cleared cache).
      await SupabaseService.hydrateCachesFromDisk(user.id);
      final profile = await SupabaseService.getCurrentUserProfileCached(user.id);

      if (!mounted) return;
      setState(() => _showSplash = false);

      Future.microtask(() => FcmService().registerToken(user.id));
      if (profile == null) {
        navigatorKey.currentState?.pushReplacementNamed('/onboarding');
      } else {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _showSplash = false);
      navigatorKey.currentState?.pushReplacementNamed('/login');
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

