import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../models/friend_model.dart';

/// Handles friend list operations in Firestore.
class FriendsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get friends list as a real-time stream.
  Stream<List<FriendModel>> watchFriends(String userId) {
    return _firestore
        .collection(FirebaseConstants.friendsCollection)
        .doc(userId)
        .collection(FirebaseConstants.friendsListSubcollection)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final friends = <FriendModel>[];
      for (final doc in snapshot.docs) {
        // Get the friend's current user data for online status
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(doc.id)
            .get();

        if (userDoc.exists) {
          friends.add(FriendModel.fromFirestore(
            {...doc.data(), ...userDoc.data()!},
            doc.id,
          ));
        }
      }
      return friends;
    });
  }

  /// Add a friend by invite code.
  /// Returns the friend's display name if successful, null if not found.
  Future<String?> addFriendByCode(String userId, String code) async {
    // Find user with this invite code
    final query = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .where(FirebaseConstants.fieldInviteCode, isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final friendDoc = query.docs.first;
    final friendId = friendDoc.id;

    // Don't add yourself
    if (friendId == userId) return null;

    // Check if already friends
    final existingFriend = await _firestore
        .collection(FirebaseConstants.friendsCollection)
        .doc(userId)
        .collection(FirebaseConstants.friendsListSubcollection)
        .doc(friendId)
        .get();

    if (existingFriend.exists) return null;

    final friendData = friendDoc.data();

    // Add friend to my list
    await _firestore
        .collection(FirebaseConstants.friendsCollection)
        .doc(userId)
        .collection(FirebaseConstants.friendsListSubcollection)
        .doc(friendId)
        .set({
      'displayName': friendData[FirebaseConstants.fieldDisplayName],
      'photoUrl': friendData[FirebaseConstants.fieldPhotoUrl],
      'addedAt': FieldValue.serverTimestamp(),
    });

    // Add me to friend's list (mutual friendship)
    final myDoc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .get();

    if (myDoc.exists) {
      final myData = myDoc.data()!;
      await _firestore
          .collection(FirebaseConstants.friendsCollection)
          .doc(friendId)
          .collection(FirebaseConstants.friendsListSubcollection)
          .doc(userId)
          .set({
        'displayName': myData[FirebaseConstants.fieldDisplayName],
        'photoUrl': myData[FirebaseConstants.fieldPhotoUrl],
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    return friendData[FirebaseConstants.fieldDisplayName] as String?;
  }

  /// Remove a friend.
  Future<void> removeFriend(String userId, String friendId) async {
    // Remove from my list
    await _firestore
        .collection(FirebaseConstants.friendsCollection)
        .doc(userId)
        .collection(FirebaseConstants.friendsListSubcollection)
        .doc(friendId)
        .delete();

    // Remove from their list
    await _firestore
        .collection(FirebaseConstants.friendsCollection)
        .doc(friendId)
        .collection(FirebaseConstants.friendsListSubcollection)
        .doc(userId)
        .delete();
  }

  /// Get my invite code.
  Future<String?> getMyInviteCode(String userId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .get();
    return doc.data()?[FirebaseConstants.fieldInviteCode] as String?;
  }
}
