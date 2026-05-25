import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../../friends/providers/friends_provider.dart';
import '../data/webrtc_service.dart';
import '../data/signaling_repository.dart';

/// Talk session state.
enum TalkState {
  idle, // No active session
  connecting, // Setting up WebRTC
  talking, // Actively sending audio
  receiving, // Receiving audio from someone
  error, // Connection error
}

/// State for the talk feature.
class TalkSessionState {
  final TalkState state;
  final bool isLocked;
  final String? errorMessage;
  final String? peerName;

  const TalkSessionState({
    this.state = TalkState.idle,
    this.isLocked = false,
    this.errorMessage,
    this.peerName,
  });

  TalkSessionState copyWith({
    TalkState? state,
    bool? isLocked,
    String? errorMessage,
    String? peerName,
  }) {
    return TalkSessionState(
      state: state ?? this.state,
      isLocked: isLocked ?? this.isLocked,
      errorMessage: errorMessage ?? this.errorMessage,
      peerName: peerName ?? this.peerName,
    );
  }
}

/// Provider for the WebRTC service.
final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  final service = WebRTCService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the signaling repository.
final signalingRepositoryProvider = Provider<SignalingRepository>((ref) {
  return SignalingRepository();
});

/// NotifierProvider for talk session state.
final talkSessionProvider =
    StateNotifierProvider<TalkSessionNotifier, TalkSessionState>((ref) {
      // Watch current user to ensure the notifier is recreated/reinitialized on login/logout
      ref.watch(currentUserProvider);
      return TalkSessionNotifier(ref);
    });

class TalkSessionNotifier extends StateNotifier<TalkSessionState> {
  final Ref _ref;
  StreamSubscription? _incomingCallSubscription;
  StreamSubscription? _currentCallSubscription;
  bool _isTalkingRequested = false;

  TalkSessionNotifier(this._ref) : super(const TalkSessionState()) {
    _listenForIncomingCalls();
  }

  /// Request microphone permission before creating a local audio stream.
  Future<bool> _ensureMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    final requested = await Permission.microphone.request();
    return requested.isGranted;
  }

  /// Start listening for incoming call documents in Firestore.
  void _listenForIncomingCalls() {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final signaling = _ref.read(signalingRepositoryProvider);
    _incomingCallSubscription = signaling.watchIncomingCalls(user.uid).listen((
      snapshot,
    ) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          _handleIncomingCall(change.doc.id, data);
        }
      }
    });
  }

  /// Handle an incoming call automatically.
  Future<void> _handleIncomingCall(
    String callId,
    Map<String, dynamic> callData,
  ) async {
    if (state.state != TalkState.idle) {
      debugPrint(
        'Ignoring incoming call $callId: Already in state ${state.state}',
      );
      return;
    }

    // Check if the call is stale (older than 20 seconds)
    final createdAt = callData[FirebaseConstants.fieldCreatedAt] as Timestamp?;
    if (createdAt != null) {
      final now = DateTime.now();
      final callTime = createdAt.toDate();
      final difference = now.difference(callTime).inSeconds;
      if (difference > 20) {
        debugPrint('Ignoring stale call $callId: ${difference}s old');
        return;
      }
    }

    debugPrint(
      'Answering incoming call: $callId from ${callData[FirebaseConstants.fieldCallerId]}',
    );
    state = state.copyWith(state: TalkState.receiving);

    try {
      final webrtc = _ref.read(webrtcServiceProvider);
      final signaling = _ref.read(signalingRepositoryProvider);

      // Set up remote stream handler
      webrtc.onRemoteStream = (MediaStream stream) {
        debugPrint(
          'Remote stream received! Tracks: ${stream.getAudioTracks().length}',
        );
        // In most cases, audio tracks start playing automatically once the stream is received
        // Ensure all tracks are enabled
        for (var track in stream.getAudioTracks()) {
          track.enabled = true;
        }
      };

      webrtc.onConnectionStateChanged = (connectionState) {
        debugPrint('Connection state changed: $connectionState');
        if (connectionState == 'disconnected' ||
            connectionState == 'failed' ||
            connectionState == 'closed') {
          state = const TalkSessionState(state: TalkState.idle);
        } else if (connectionState == 'connected') {
          state = state.copyWith(state: TalkState.receiving);
        }
      };

      await webrtc.answerIncomingTalk(callId, callData);

      // Listen for call document deletion to stop receiving
      _currentCallSubscription = signaling.watchCallDocument(callId).listen((
        snapshot,
      ) {
        if (!snapshot.exists) {
          debugPrint('Call document deleted, stopping talk session');
          stopTalking();
        }
      });

      // Auto-timeout if connection doesn't happen in 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && state.state == TalkState.receiving) {
          debugPrint('Incoming call timed out waiting for connection');
          stopTalking();
        }
      });
    } catch (e) {
      debugPrint('Error answering call: $e');
      state = TalkSessionState(
        state: TalkState.error,
        errorMessage: 'Error receiving audio: $e',
      );
      // Auto-reset after error
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = const TalkSessionState(state: TalkState.idle);
        }
      });
    }
  }

  /// Start talking to the selected friend.
  Future<void> startTalking() async {
    if (state.state != TalkState.idle) return;

    final user = _ref.read(currentUserProvider);
    final selectedFriend = _ref.read(selectedFriendProvider);

    if (user == null || selectedFriend == null) {
      state = state.copyWith(
        state: TalkState.error,
        errorMessage: 'Select a friend first',
      );
      return;
    }

    _isTalkingRequested = true;
    state = state.copyWith(
      state: TalkState.connecting,
      peerName: selectedFriend.displayName,
    );

    try {
      final hasMicPermission = await _ensureMicrophonePermission();
      if (!hasMicPermission) {
        state = const TalkSessionState(
          state: TalkState.error,
          errorMessage: 'Microphone permission is required to talk',
        );
        return;
      }

      final webrtc = _ref.read(webrtcServiceProvider);

      webrtc.onRemoteStream = (MediaStream stream) {
        // Remote stream received (if receiver also sends audio back)
      };

      webrtc.onConnectionStateChanged = (connectionState) {
        if (connectionState == 'connected') {
          state = state.copyWith(state: TalkState.talking);
        } else if (connectionState == 'disconnected' ||
            connectionState == 'failed') {
          state = state.copyWith(state: TalkState.error);
        }
      };

      await webrtc.startTalking(
        callerId: user.uid,
        receiverId: selectedFriend.uid,
      );

      // Check if user already released the button while we were connecting
      if (!_isTalkingRequested) {
        debugPrint('Talking requested but cancelled before connection');
        await stopTalking();
        return;
      }

      state = state.copyWith(state: TalkState.talking);
    } catch (e) {
      _isTalkingRequested = false;
      state = TalkSessionState(
        state: TalkState.error,
        errorMessage: 'Unable to start microphone: $e',
      );
    }
  }

  /// Toggle session lock.
  void setLocked(bool locked) {
    state = state.copyWith(isLocked: locked);
  }

  /// Stop the current talk session.
  Future<void> stopTalking() async {
    _isTalkingRequested = false;
    try {
      _currentCallSubscription?.cancel();
      _currentCallSubscription = null;
      
      final webrtc = _ref.read(webrtcServiceProvider);
      await webrtc.stopTalking();
    } finally {
      state = const TalkSessionState(state: TalkState.idle, isLocked: false);
    }
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _currentCallSubscription?.cancel();
    super.dispose();
  }
}
