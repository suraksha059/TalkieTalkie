import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talk_show/core/constants/firebase_constants.dart';

/// Manages user online/offline presence in Firestore.
class PresenceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _heartbeatTimer;

  /// Start tracking presence for the current user.
  void startTracking(String userId) {
    // Set online immediately
    _setOnline(userId);

    // Heartbeat every 60 seconds to keep presence alive
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _setOnline(userId),
    );
  }

  /// Stop tracking presence.
  Future<void> stopTracking(String userId) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _setOffline(userId);
  }

  /// Set user as online.
  Future<void> _setOnline(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        FirebaseConstants.fieldIsOnline: true,
        FirebaseConstants.fieldLastSeen: FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silently fail if document doesn't exist yet
    }
  }

  /// Set user as offline.
  Future<void> _setOffline(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        FirebaseConstants.fieldIsOnline: false,
        FirebaseConstants.fieldLastSeen: FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silently fail
    }
  }

  /// Watch a specific user's online status.
  Stream<bool> watchUserPresence(String userId) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?[FirebaseConstants.fieldIsOnline] ?? false);
  }

  /// Dispose resources.
  void dispose() {
    _heartbeatTimer?.cancel();
  }
}
