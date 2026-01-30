import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../screens/chat_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Navigator key 설정 (앱 시작 시 main.dart에서 호출)
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// 알림 초기화 (앱 시작 시 한 번 호출)
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    _initialized = true;
  }

  /// 알림 탭 시 처리: 해당 대화로 이동
  void _onNotificationTapped(NotificationResponse response) {
    final conversationId = response.payload;
    if (conversationId == null || conversationId.isEmpty) return;
    if (_navigatorKey?.currentContext == null) return;

    // 대화 정보 가져오기 및 채팅 화면으로 이동
    Future.microtask(() async {
      try {
        final conversation = await SupabaseService.getConversation(conversationId);
        if (conversation == null) return;

        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser == null) return;

        // 상대방 ID 찾기
        final trainerId = conversation['trainer_id'] as String?;
        final traineeId = conversation['trainee_id'] as String?;
        final otherUserId = (trainerId == currentUser.id) ? traineeId : trainerId;
        if (otherUserId == null) return;

        // 상대방 프로필 가져오기
        final otherProfile = await SupabaseService.getPublicProfile(otherUserId);

        // 채팅 화면으로 이동
        if (_navigatorKey?.currentContext != null) {
          Navigator.of(_navigatorKey!.currentContext!).push(
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
        print('Failed to navigate to chat from notification: $e');
      }
    });
  }

  /// 새 메시지 알림 표시
  Future<void> showNewMessageNotification({
    required String senderName,
    required String messageContent,
    String? conversationId,
  }) async {
    if (kIsWeb || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = 'New message from $senderName';
    final body = messageContent.length > 100
        ? '${messageContent.substring(0, 100)}...'
        : messageContent;

    await _notifications.show(
      conversationId?.hashCode ?? DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: conversationId,
    );
  }

  /// 알림 권한 요청 (Android 13+)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    return true;
  }
}
