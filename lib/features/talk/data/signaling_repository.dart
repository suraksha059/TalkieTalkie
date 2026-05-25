import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';

/// Handles WebRTC signaling through Firestore.
/// Replaces the need for a custom WebSocket/Node.js signaling server.
class SignalingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new call document (caller side).
  Future<String> createCall({
    required String callId,
    required String callerId,
    required String receiverId,
    required String sdp,
    required String sdpType,
  }) async {
    await _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId)
        .set({
      FirebaseConstants.fieldCallerId: callerId,
      FirebaseConstants.fieldReceiverId: receiverId,
      FirebaseConstants.fieldCallerSdp: sdp,
      FirebaseConstants.fieldCallerSdpType: sdpType,
      FirebaseConstants.fieldStatus: FirebaseConstants.statusRinging,
      FirebaseConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
    });

    return callId;
  }

  /// Answer a call (receiver side).
  Future<void> answerCall({
    required String callId,
    required String sdp,
    required String sdpType,
  }) async {
    await _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId)
        .update({
      FirebaseConstants.fieldReceiverSdp: sdp,
      FirebaseConstants.fieldReceiverSdpType: sdpType,
      FirebaseConstants.fieldStatus: FirebaseConstants.statusActive,
    });
  }

  /// Add an ICE candidate (caller side).
  Future<void> addCallerCandidate(String callId, Map<String, dynamic> candidate) async {
    await _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId)
        .collection(FirebaseConstants.callerCandidatesSubcollection)
        .add(candidate);
  }

  /// Add an ICE candidate (receiver side).
  Future<void> addReceiverCandidate(String callId, Map<String, dynamic> candidate) async {
    await _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId)
        .collection(FirebaseConstants.receiverCandidatesSubcollection)
        .add(candidate);
  }

  /// Listen for receiver's answer (caller side).
  Stream<DocumentSnapshot> watchCallDocument(String callId) {
    return _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId)
        .snapshots();
  }

  /// Listen for caller's ICE candidates (receiver side).
  Stream<QuerySnapshot> watchCallerCandidates(String callId) {
    return _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId)
        .collection(FirebaseConstants.callerCandidatesSubcollection)
        .snapshots();
  }

  /// Listen for receiver's ICE candidates (caller side).
  Stream<QuerySnapshot> watchReceiverCandidates(String callId) {
    return _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId)
        .collection(FirebaseConstants.receiverCandidatesSubcollection)
        .snapshots();
  }

  /// Listen for incoming calls (receiver side).
  Stream<QuerySnapshot> watchIncomingCalls(String receiverId) {
    return _firestore
        .collection(FirebaseConstants.callsCollection)
        .where(FirebaseConstants.fieldReceiverId, isEqualTo: receiverId)
        .where(FirebaseConstants.fieldStatus,
            isEqualTo: FirebaseConstants.statusRinging)
        .snapshots();
  }

  /// End a call — delete the document and subcollections.
  Future<void> endCall(String callId) async {
    final callDoc = _firestore
        .collection(FirebaseConstants.callsCollection)
        .doc(callId);

    // Delete caller candidates
    final callerCandidates = await callDoc
        .collection(FirebaseConstants.callerCandidatesSubcollection)
        .get();
    for (final doc in callerCandidates.docs) {
      await doc.reference.delete();
    }

    // Delete receiver candidates
    final receiverCandidates = await callDoc
        .collection(FirebaseConstants.receiverCandidatesSubcollection)
        .get();
    for (final doc in receiverCandidates.docs) {
      await doc.reference.delete();
    }

    // Delete the call document
    await callDoc.delete();
  }
}
