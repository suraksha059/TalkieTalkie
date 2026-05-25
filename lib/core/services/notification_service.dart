import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM push notifications for waking the receiver's device.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM and local notifications.
  Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Get FCM token for this device.
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Listen for token refresh events.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'incoming_talk') {
      _showTalkNotification(
        title: data['senderName'] ?? 'Someone',
        body: 'is talking to you! 🎙️',
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to talk screen if needed
    // This will be connected to the router later
  }

  Future<void> _showTalkNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'talk_channel',
      'Talk Notifications',
      channelDescription: 'Notifications for incoming voice messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }
}

/// Top-level handler for background messages.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle data message in background
  // For MVP, this just ensures the app wakes up
}
