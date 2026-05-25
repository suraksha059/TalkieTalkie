import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import 'signaling_repository.dart';

/// Manages WebRTC peer connections for push-to-talk audio.
class WebRTCService {
  final SignalingRepository _signaling = SignalingRepository();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  String? _currentCallId;
  final List<RTCIceCandidate> _remoteCandidatesBuffer = [];
  bool _isRemoteDescriptionSet = false;

  // Callbacks
  Function(MediaStream)? onRemoteStream;
  Function(String)? onConnectionStateChanged;

  /// ICE server configuration.
  /// Uses free Google STUN + metered.ca TURN servers.
  static final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Add your metered.ca TURN servers here:
      // {
      //   'urls': 'turn:a.relay.metered.ca:80',
      //   'username': 'YOUR_USERNAME',
      //   'credential': 'YOUR_CREDENTIAL',
      // },
    ],
  };

  /// Start a talk session (caller side).
  /// Called when user presses the talk button.
  Future<void> startTalking({
    required String callerId,
    required String receiverId,
  }) async {
    _currentCallId = const Uuid().v4();

    // 1. Create peer connection
    _peerConnection = await createPeerConnection(_iceServers);

    // 2. Get local audio stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'highpassFilter': true,
      },
      'video': false,
    });

    // Ensure audio is routed to speakerphone
    await Helper.setSpeakerphoneOn(true);

    // 3. Add audio tracks to peer connection
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = true;
      await _peerConnection!.addTrack(track, _localStream!);
    }
    
    // Explicitly set direction to sendrecv for audio
    final transceivers = await _peerConnection!.getTransceivers();
    for (final transceiver in transceivers) {
      if (transceiver.receiver.track?.kind == 'audio') {
        transceiver.setDirection(TransceiverDirection.SendRecv);
      }
    }

    // 4. Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _signaling.addCallerCandidate(_currentCallId!, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // 5. Handle remote stream
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        onRemoteStream?.call(event.streams[0]);
      }
    };

    // 6. Handle connection state
    _peerConnection!.onConnectionState = (state) {
      onConnectionStateChanged?.call(state.name);
    };

    // 7. Create SDP offer
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);

    // 8. Write offer to Firestore
    await _signaling.createCall(
      callId: _currentCallId!,
      callerId: callerId,
      receiverId: receiverId,
      sdp: offer.sdp!,
      sdpType: offer.type!,
    );

    // 9. Listen for receiver's answer
    _signaling.watchCallDocument(_currentCallId!).listen((snapshot) async {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      if (data['receiverSdp'] != null &&
          _peerConnection?.signalingState ==
              RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        final answer = RTCSessionDescription(
          data['receiverSdp'],
          data['receiverSdpType'],
        );
        await _peerConnection!.setRemoteDescription(answer);
        _isRemoteDescriptionSet = true;
        
        // Add buffered candidates
        for (final candidate in _remoteCandidatesBuffer) {
          await _peerConnection!.addCandidate(candidate);
        }
        _remoteCandidatesBuffer.clear();
      }
    });

    // 10. Listen for receiver's ICE candidates
    _signaling.watchReceiverCandidates(_currentCallId!).listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
          
          if (_isRemoteDescriptionSet) {
            await _peerConnection!.addCandidate(candidate);
          } else {
            _remoteCandidatesBuffer.add(candidate);
          }
        }
      }
    });
  }

  /// Answer an incoming talk session (receiver side).
  /// Called automatically when receiver detects incoming call.
  Future<void> answerIncomingTalk(String callId, Map<String, dynamic> callData) async {
    _currentCallId = callId;

    // 1. Create peer connection
    _peerConnection = await createPeerConnection(_iceServers);

    // 2. Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _signaling.addReceiverCandidate(_currentCallId!, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // 3. Handle remote stream (incoming audio)
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        onRemoteStream?.call(event.streams[0]);
      }
    };

    // 4. Handle connection state
    _peerConnection!.onConnectionState = (state) {
      onConnectionStateChanged?.call(state.name);
    };

    // 5. Set remote description (caller's offer)
    final offer = RTCSessionDescription(
      callData['callerSdp'],
      callData['callerSdpType'],
    );
    await _peerConnection!.setRemoteDescription(offer);
    _isRemoteDescriptionSet = true;

    // Ensure audio is routed to speakerphone
    await Helper.setSpeakerphoneOn(true);

    // 6. Create SDP answer
    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(answer);

    // 7. Write answer to Firestore
    await _signaling.answerCall(
      callId: _currentCallId!,
      sdp: answer.sdp!,
      sdpType: answer.type!,
    );

    // 8. Listen for caller's ICE candidates
    _signaling.watchCallerCandidates(_currentCallId!).listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );

          if (_isRemoteDescriptionSet) {
            await _peerConnection!.addCandidate(candidate);
          } else {
            _remoteCandidatesBuffer.add(candidate);
          }
        }
      }
    });

    // Process any buffered candidates that might have arrived during answer creation
    if (_remoteCandidatesBuffer.isNotEmpty) {
      final candidates = List<RTCIceCandidate>.from(_remoteCandidatesBuffer);
      _remoteCandidatesBuffer.clear();
      for (final candidate in candidates) {
        await _peerConnection!.addCandidate(candidate);
      }
    }
  }

  /// Stop the current talk session.
  /// Called when user releases the talk button.
  Future<void> stopTalking() async {
    // Stop local audio tracks
    _localStream?.getAudioTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    // Close peer connection
    await _peerConnection?.close();
    _peerConnection = null;

    // Clean up Firestore
    if (_currentCallId != null) {
      await _signaling.endCall(_currentCallId!);
      _currentCallId = null;
    }
    
    _remoteCandidatesBuffer.clear();
    _isRemoteDescriptionSet = false;
    onRemoteStream = null;
    onConnectionStateChanged = null;
  }

  /// Mute/unmute the local microphone.
  void setMicEnabled(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  /// Check if currently in a talk session.
  bool get isActive => _peerConnection != null;

  /// Get current call ID.
  String? get currentCallId => _currentCallId;

  /// Dispose of all resources.
  Future<void> dispose() async {
    await stopTalking();
  }
}
