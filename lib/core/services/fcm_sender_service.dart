import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Service to send client-to-client high-priority FCM HTTP v1 data push notifications.
///
/// NOTE: Direct client-to-client push notification sending requires exposing the
/// Firebase Service Account JSON credentials. In production, this should be handled
/// securely via a backend (e.g., Firebase Cloud Functions).
class FcmSenderService {
  FcmSenderService._();

  /// Your Firebase Service Account Credentials JSON.
  /// Retrieve this from: Firebase Console -> Project Settings -> Service Accounts -> Generate New Private Key.
  ///
  /// IMPORTANT: Paste the contents of your downloaded Service Account JSON file as the map below.
  static const Map<String, dynamic> _serviceAccountJson = {
    "type": "service_account",
    "project_id": "talkwith-m",
    "private_key_id": "0cd701c147d2e40c875474be8408476e96e41e4f",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDwpp4XZEugv5X/\nSia7+Hn5IDJXQKw+VE/VaVl1HF3sXFrM5tBkqy7MKsAKCgMaUKCsNRdM2VOg1yRP\nhHySYTEK+ZnioiO0oZxlAhF8d/RoAjqmw0sla6EqkbzQxH3SlkbFkH5dxzQhKhpU\ncDH4nNZREMSuG4qmEuQ8H2m/hKCJQiNiIXtT/9hGSswFxxc2wMYlEBxN8zWFEuCG\nhd+0AgJ/s4f6Vm35WUeBEkFW0evvGyvvkEFcnzA0Kne7eKeZ0MRHlsq7SS3VWVfj\n6FDYmNTLKm/gxSiiw/Uq/hgMTioL9ZVYx1agUIu6WYKB8TfNbQNVW0sU11zwZqPy\n1FnLc+xhAgMBAAECggEABWLnVDT0m+QZ5IFJgWjP+xdhRRJvoIQE1u0hGVXRlNwi\n1KYAaVZrCVsWGgtsExtVo1EbZMcS//08xPJdUu3tufYI/5l7NNxuqpSbpVZugCL3\notqpbIyeinxBVodlXRCrxBmGOI1gQXNGrFfoCG1jPySB0HdRmMLAvMdDt8uNR9Ep\n6fCHGGWN+2ow4Dr55oO2F+FGdjMgDPV0PvwlYeYwwgmp425Fl70ty1dVeSHLXvF1\nkEGKv6PVX+VEI7OyERsHQoodAE6P00QW6nAYd6+XzKYNlVekU0gRndVhHBhfmpMa\naWkV9aOf9y86Tjf7WTmlKJ8GxgvtO9fE+Us+qLmXaQKBgQD+tnYiGvqyQqneNMuP\nZJMyHh0GHCLD/AosDHNBAM+KaNwWIZBvPdE7L2WW1kW3L5WmXFiULkhr8qSE89hF\nZ9o92cIMjN7QswlyFB7T2Gq78c647ZEM2ke6l+wsWFHdIMnDwm+79uhpa3OnnGLB\njqbUF8lB/1EJMkelB91cwQpBuQKBgQDx3faavyKIYjt1vPBASn2Tv9r3DAmC/pg7\n+yC2u3liYxPBJmKlItgJyPVzpKYI27x+n0NIA7hBdNReEmpjUhR6l+mid+CwBIyk\njtdx021BGW7fFhGAmqBqf1mSRAL8GlIxnWkk87G4Rsrks3Zo8g02gIhCRT4zfx5Z\n/BhaFlhz6QKBgQDgJCJKmuE3UtB2mJD06zVYqgUyZjn1quosnvwhHJyFmQbrdrfK\nHGTtpyTHmmEY9YfEMIlGRIA4dfpugMI1OVFkkiZfsus0Tgim2avTEiPCpeQa+ftl\niwQJ4DzVPRc09vB2ErkOeBVHB2Zr/YMt/uExzIivSgS+if9f607Rm5HyCQKBgQC4\nGGWq1Y7YVkTB0iTgGpLI0gA9iDj5LwX6qaP10m6K97TCkJAG96WOlRpWgl0qYu5v\nRpP0jXhCwkUesU+u93vE8DoRwsMP1vaiDmNoLTB8m3orbWW3CHrPdM1dqkzHTNWB\nFDpCuQZtp9ypBPw81vg9osmT/5ZfpgMZJOv4Lgf3eQKBgQCRX+i3Z3Ye3iBmfVai\n234XLxcZmcylHr5ztP6HqmDiI+wUhz/+cPl9os3x2T/CBufzOsCMegUYRCOLesIH\nkmvcZs3KelHOLSea0+ha3Xc3DxhEScjtbO3u7a1ffur4U4AyXaT3vij71akkGDri\nB6KmYX29+i8On1M4TPedA8TGcA==\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@talkwith-m.iam.gserviceaccount.com",
    "client_id": "117975773708502571795",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40talkwith-m.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  /// Generates the Google OAuth2 access token for calling FCM HTTP v1 APIs.
  static Future<String?> _getAccessToken() async {
    if (_serviceAccountJson['private_key'] == 'YOUR_PRIVATE_KEY' ||
        _serviceAccountJson['private_key'].toString().isEmpty) {
      debugPrint(
        'FCM Sender: Service Account Key is not configured. '
        'Please generate and paste your Firebase Service Account JSON in lib/core/services/fcm_sender_service.dart.',
      );
      return null;
    }

    try {
      final credentials = ServiceAccountCredentials.fromJson(
        _serviceAccountJson,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
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

    try {
      final client = HttpClient();
      final projectId = _serviceAccountJson['project_id'] ?? 'talkwith-m';
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
            'headers': {
              'apns-priority': '10', // High priority delivery
            },
            'payload': {
              'aps': {
                'content-available': 1, // Wakes up iOS apps in background
              },
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
