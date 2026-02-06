import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_navigation.dart';
import '../screens/chat_screen.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

/// Background message handler - must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification is shown by FCM when payload includes "notification" field.
  // We only need to handle data for any future logic (e.g. analytics).
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle notification tap when app was terminated
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _initialized = true;
    } catch (e) {
      debugPrint('FcmService init failed: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final conversationId = message.data['conversation_id'] as String?;
    if (conversationId == null || conversationId.isEmpty) return;

    Future.microtask(() async {
      try {
        final conversation = await SupabaseService.getConversation(conversationId);
        if (conversation == null) return;

        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) return;

        final trainerId = conversation['trainer_id'] as String?;
        final traineeId = conversation['trainee_id'] as String?;
        final otherUserId = (trainerId == currentUser.id) ? traineeId : trainerId;
        if (otherUserId == null) return;

        final otherProfile = await SupabaseService.getPublicProfile(otherUserId);
        final navigator = navigatorKey.currentState;
        if (navigator != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversationId,
                otherUserId: otherUserId,
                otherProfile: otherProfile,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed to navigate from FCM tap: $e');
      }
    });
  }

  /// Register FCM token with Supabase. Call when user logs in.
  Future<void> registerToken(String userId) async {
    if (kIsWeb || !_initialized) return;
    if (!NotificationService().chatNotificationsEnabled.value) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      await Supabase.instance.client.from('user_fcm_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'platform': platform,
          'notifications_enabled': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  /// Update notifications_enabled for current token. Call when user toggles in More.
  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (kIsWeb || !_initialized) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      if (enabled) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) await registerToken(user.id);
      } else {
        await Supabase.instance.client
            .from('user_fcm_tokens')
            .update({
              'notifications_enabled': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('fcm_token', token);
      }
    } catch (e) {
      debugPrint('FCM update notifications failed: $e');
    }
  }

  /// Remove token on logout. Call when user signs out.
  Future<void> unregisterToken() async {
    if (kIsWeb || !_initialized) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('user_fcm_tokens')
            .delete()
            .eq('fcm_token', token);
      }
    } catch (e) {
      debugPrint('FCM token unregister failed: $e');
    }
  }
}
