import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

/// Service to send client-to-client high-priority FCM HTTP v1 data push notifications.
///
/// Credentials are loaded from the bundled asset file:
///   assets/service_account.json
///
/// This file is excluded from git via .gitignore.
/// Copy assets/service_account.json.example -> assets/service_account.json
/// and fill in your real Firebase Service Account credentials.
class FcmSenderService {
  FcmSenderService._();

  static Map<String, dynamic>? _cachedCredentials;

  /// Loads service account credentials from the bundled asset file.
  static Future<Map<String, dynamic>?> _loadCredentials() async {
    if (_cachedCredentials != null) return _cachedCredentials;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );
      _cachedCredentials = jsonDecode(jsonString) as Map<String, dynamic>;
      return _cachedCredentials;
    } catch (e) {
      debugPrint(
        'FCM Sender: Could not load assets/service_account.json. '
        'Make sure you have copied service_account.json.example to service_account.json '
        'and filled in your real Firebase Service Account credentials. Error: $e',
      );
      return null;
    }
  }

  /// Generates the Google OAuth2 access token for calling FCM HTTP v1 APIs.
  static Future<String?> _getAccessToken() async {
    final credentials = await _loadCredentials();
    if (credentials == null) return null;

    final privateKey = credentials['private_key']?.toString() ?? '';
    if (privateKey.isEmpty || privateKey.contains('YOUR_PRIVATE_KEY')) {
      debugPrint(
        'FCM Sender: Service Account credentials are not configured. '
        'Please fill in the real values in assets/service_account.json.',
      );
      return null;
    }

    try {
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
        credentials,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(
        serviceAccountCredentials,
        scopes,
      );
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      debugPrint('FCM Sender: Error generating access token: $e');
      return null;
    }
  }

  /// Sends a high-priority FCM HTTP v1 data notification to wake up the receiver's phone.
  static Future<void> sendIncomingTalkNotification({
    required String receiverFcmToken,
    required String callId,
    required String senderId,
    required String senderName,
  }) async {
    if (receiverFcmToken.isEmpty) {
      debugPrint(
        'FCM Sender: Receiver token is empty. Cannot send push notification.',
      );
      return;
    }

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      debugPrint(
        'FCM Sender: Access token generation failed. Cannot send push notification.',
      );
      return;
    }

    final credentials = await _loadCredentials();
    final projectId = credentials?['project_id'] ?? 'talkwith-m';

    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );
      final request = await client.postUrl(uri);

      // Add headers
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );

      // Add FCM v1 payload
      final payload = {
        'message': {
          'token': receiverFcmToken,
          'data': {
            'type': 'incoming_talk',
            'callId': callId,
            'senderId': senderId,
            'senderName': senderName,
          },
          'android': {'priority': 'HIGH'},
          'apns': {
            'headers': {'apns-priority': '10'},
            'payload': {
              'aps': {'content-available': 1},
            },
          },
        },
      };

      request.write(jsonEncode(payload));
      final response = await request.close();

      if (response.statusCode == 200) {
        debugPrint(
          'FCM Sender: Successfully sent background talk notification via FCM v1.',
        );
      } else {
        final responseBody = await response.transform(utf8.decoder).join();
        debugPrint(
          'FCM Sender: Failed to send notification. Status: ${response.statusCode}, Body: $responseBody',
        );
      }
    } catch (e) {
      debugPrint('FCM Sender: Error sending FCM notification: $e');
    }
  }
}
