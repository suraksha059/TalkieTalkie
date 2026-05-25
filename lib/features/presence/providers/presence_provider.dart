import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/presence_repository.dart';

/// Provider for the PresenceRepository.
final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  final repo = PresenceRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Provider that manages presence tracking lifecycle.
/// Automatically starts/stops tracking based on auth state.
final presenceTrackingProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final presenceRepo = ref.watch(presenceRepositoryProvider);

  if (user != null) {
    presenceRepo.startTracking(user.uid);
    ref.onDispose(() => presenceRepo.stopTracking(user.uid));
  }
});
