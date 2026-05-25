import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String uid;
  final String displayName;
  final String photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? addedAt;

  const FriendModel({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
    this.addedAt,
  });

  factory FriendModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return FriendModel(
      uid: uid,
      displayName: data['displayName'] ?? 'Unknown',
      photoUrl: data['photoUrl'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Time-ago string for last seen
  String get lastSeenText {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
