import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final String? callerSdp;
  final String? receiverSdp;
  final String? callerSdpType;
  final String? receiverSdpType;
  final String status;
  final DateTime? createdAt;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    this.callerSdp,
    this.receiverSdp,
    this.callerSdpType,
    this.receiverSdpType,
    this.status = 'ringing',
    this.createdAt,
  });

  factory CallModel.fromFirestore(Map<String, dynamic> data, String callId) {
    return CallModel(
      callId: callId,
      callerId: data['callerId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      callerSdp: data['callerSdp'],
      receiverSdp: data['receiverSdp'],
      callerSdpType: data['callerSdpType'],
      receiverSdpType: data['receiverSdpType'],
      status: data['status'] ?? 'ringing',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'callerId': callerId,
      'receiverId': receiverId,
      if (callerSdp != null) 'callerSdp': callerSdp,
      if (receiverSdp != null) 'receiverSdp': receiverSdp,
      if (callerSdpType != null) 'callerSdpType': callerSdpType,
      if (receiverSdpType != null) 'receiverSdpType': receiverSdpType,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  CallModel copyWith({
    String? callerSdp,
    String? receiverSdp,
    String? callerSdpType,
    String? receiverSdpType,
    String? status,
  }) {
    return CallModel(
      callId: callId,
      callerId: callerId,
      receiverId: receiverId,
      callerSdp: callerSdp ?? this.callerSdp,
      receiverSdp: receiverSdp ?? this.receiverSdp,
      callerSdpType: callerSdpType ?? this.callerSdpType,
      receiverSdpType: receiverSdpType ?? this.receiverSdpType,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
