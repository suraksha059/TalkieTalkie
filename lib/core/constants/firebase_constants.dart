class FirebaseConstants {
  FirebaseConstants._();

  // Collection names
  static const String usersCollection = 'users';
  static const String friendsCollection = 'friends';
  static const String callsCollection = 'calls';
  static const String friendsListSubcollection = 'friendsList';
  static const String callerCandidatesSubcollection = 'callerCandidates';
  static const String receiverCandidatesSubcollection = 'receiverCandidates';

  // User document fields
  static const String fieldDisplayName = 'displayName';
  static const String fieldEmail = 'email';
  static const String fieldPhotoUrl = 'photoUrl';
  static const String fieldInviteCode = 'inviteCode';
  static const String fieldFcmToken = 'fcmToken';
  static const String fieldIsOnline = 'isOnline';
  static const String fieldLastSeen = 'lastSeen';
  static const String fieldCreatedAt = 'createdAt';

  // Call document fields
  static const String fieldCallerId = 'callerId';
  static const String fieldReceiverId = 'receiverId';
  static const String fieldCallerSdp = 'callerSdp';
  static const String fieldReceiverSdp = 'receiverSdp';
  static const String fieldCallerSdpType = 'callerSdpType';
  static const String fieldReceiverSdpType = 'receiverSdpType';
  static const String fieldStatus = 'status';

  // Call status values
  static const String statusRinging = 'ringing';
  static const String statusActive = 'active';
  static const String statusEnded = 'ended';
}
