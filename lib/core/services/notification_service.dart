import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../../features/talk/data/webrtc_service.dart';
import '../../features/talk/data/signaling_repository.dart';
import '../constants/firebase_constants.dart';

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
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Background FCM: Firebase already initialized or error: $e');
  }

  final data = message.data;
  final type = data['type'];
  
  if (type == 'incoming_talk') {
    final callId = data['callId'];
    if (callId == null) {
      debugPrint('Background FCM: Missing callId in payload.');
      return;
    }

    final senderName = data['senderName'] ?? 'Someone';
    debugPrint('Background FCM: Handling incoming talk for call $callId from $senderName');

    try {
      final signaling = SignalingRepository();
      final webrtc = WebRTCService();

      // Retrieve call document from Firestore to get the caller's SDP offer
      final callDoc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.callsCollection)
          .doc(callId)
          .get();

      if (!callDoc.exists) {
        debugPrint('Background FCM: Call document $callId does not exist in Firestore. Aborting.');
        return;
      }

      final callData = callDoc.data();
      if (callData == null) return;

      // Configure WebRTC remote stream (incoming audio)
      webrtc.onRemoteStream = (MediaStream stream) {
        debugPrint('Background FCM: Remote audio stream received and active!');
        for (var track in stream.getAudioTracks()) {
          track.enabled = true;
        }
      };

      webrtc.onConnectionStateChanged = (state) {
        debugPrint('Background FCM: Connection state changed to: $state');
      };

      // Auto-answer the call in the background
      await webrtc.answerIncomingTalk(callId, callData);

      // Listen for the call document deletion to stop receiving audio
      StreamSubscription? callSubscription;
      callSubscription = signaling.watchCallDocument(callId).listen((snapshot) async {
        if (!snapshot.exists) {
          debugPrint('Background FCM: Call ended by caller. Stopping audio streaming.');
          await webrtc.stopTalking();
          callSubscription?.cancel();
        }
      });

      // Auto-timeout after 30 seconds to prevent background audio leaks if call hangs
      Future.delayed(const Duration(seconds: 30), () async {
        if (webrtc.isActive && webrtc.currentCallId == callId) {
          debugPrint('Background FCM: Auto-timeout reached. Stopping audio session.');
          await webrtc.stopTalking();
          callSubscription?.cancel();
        }
      });

    } catch (e) {
      debugPrint('Background FCM: Error processing background talk session: $e');
    }
  }
}
