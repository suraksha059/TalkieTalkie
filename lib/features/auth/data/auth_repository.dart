import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:talk_show/core/constants/firebase_constants.dart';
import 'package:talk_show/core/utils/invite_code_generator.dart';
import 'package:talk_show/core/services/notification_service.dart';

/// Handles all Firebase Authentication logic.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Current user stream.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user.
  User? get currentUser => _auth.currentUser;

  /// Sign in with Google.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Create user document if first time
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _createUserDocument(userCredential.user!);
    } else {
      // Update FCM token on existing account
      await _updateFcmToken(userCredential.user!.uid);
    }

    return userCredential;
  }

  /// Create user document in Firestore.
  Future<void> _createUserDocument(User user) async {
    final inviteCode = InviteCodeGenerator.generate();
    final fcmToken = await NotificationService.instance.getToken();

    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(user.uid)
        .set({
      FirebaseConstants.fieldDisplayName: user.displayName ?? 'User',
      FirebaseConstants.fieldEmail: user.email ?? '',
      FirebaseConstants.fieldPhotoUrl: user.photoURL ?? '',
      FirebaseConstants.fieldInviteCode: inviteCode,
      FirebaseConstants.fieldFcmToken: fcmToken ?? '',
      FirebaseConstants.fieldIsOnline: true,
      FirebaseConstants.fieldLastSeen: FieldValue.serverTimestamp(),
      FirebaseConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
    });
  }

  /// Update FCM token.
  Future<void> _updateFcmToken(String uid) async {
    final fcmToken = await NotificationService.instance.getToken();
    if (fcmToken != null) {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .update({
        FirebaseConstants.fieldFcmToken: fcmToken,
        FirebaseConstants.fieldIsOnline: true,
        FirebaseConstants.fieldLastSeen: FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    // Set offline before signing out
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(uid)
            .update({
          FirebaseConstants.fieldIsOnline: false,
          FirebaseConstants.fieldLastSeen: FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Silently fail if we can't update status (e.g. permission denied)
        // We still want to proceed with sign out
      }
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
