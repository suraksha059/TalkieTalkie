import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

/// Provider for the AuthRepository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream provider for auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current user provider (synchronous access).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Loading state for sign-in.
final authLoadingProvider = StateProvider<bool>((ref) => false);
