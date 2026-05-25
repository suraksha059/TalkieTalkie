import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/friends_repository.dart';
import '../models/friend_model.dart';

/// Provider for the FriendsRepository instance.
final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository();
});

/// Stream provider for friends list.
final friendsListProvider = StreamProvider<List<FriendModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return ref.watch(friendsRepositoryProvider).watchFriends(user.uid);
});

/// Provider for my invite code.
final myInviteCodeProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  return ref.watch(friendsRepositoryProvider).getMyInviteCode(user.uid);
});

/// Currently selected friend for talking.
final selectedFriendProvider = StateProvider<FriendModel?>((ref) => null);
