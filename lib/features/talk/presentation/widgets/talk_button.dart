import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../providers/talk_provider.dart';

/// The central push-to-talk button.
/// Press and hold to talk, release to stop.
class TalkButton extends StatefulWidget {
  final bool isEnabled;
  final TalkState talkState;
  final bool isLocked;
  final VoidCallback onTalkStart;
  final VoidCallback onTalkEnd;
  final VoidCallback onLock;

  const TalkButton({
    super.key,
    required this.isEnabled,
    required this.talkState,
    required this.isLocked,
    required this.onTalkStart,
    required this.onTalkEnd,
    required this.onLock,
  });

  @override
  State<TalkButton> createState() => _TalkButtonState();
}

class _TalkButtonState extends State<TalkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;
  bool _isDraggingToLock = false;

  // For manual double tap detection
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(TalkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.talkState == TalkState.talking || widget.isLocked) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (widget.talkState == TalkState.receiving) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isLocked) return;

    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      // Double tap detected
      HapticUtils.talkEnd();
      widget.onTalkEnd();
      _lastTapTime = null;
    } else {
      _lastTapTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTalking =
        widget.talkState == TalkState.talking || widget.isLocked;
    final bool isReceiving = widget.talkState == TalkState.receiving;
    final bool isConnecting = widget.talkState == TalkState.connecting;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Lock Icon Area
        if (widget.isEnabled && (isTalking || _isPressed) && !widget.isLocked)
          Positioned(
            top: -90,
            child:
                Opacity(
                      opacity: _isPressed ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isDraggingToLock
                                      ? AppColors.accent.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_open_rounded,
                                  color: _isDraggingToLock
                                      ? AppColors.accent
                                      : Colors.white.withValues(alpha: 0.3),
                                  size: 28,
                                ),
                              )
                              .animate(target: _isDraggingToLock ? 1 : 0)
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.3, 1.3),
                                curve: Curves.elasticOut,
                              ),
                          const SizedBox(height: 8),
                          Text(
                            'Slide to lock',
                            style: TextStyle(
                              color: _isDraggingToLock
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(target: _isPressed ? 1 : 0)
                    .fadeIn()
                    .moveY(begin: 10, end: 0),
          ),

        // Main Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _handleTap(),
          onLongPressStart: widget.isEnabled && !widget.isLocked
              ? (_) {
                  setState(() => _isPressed = true);
                  HapticUtils.talkStart();
                  widget.onTalkStart();
                }
              : null,
          onLongPressMoveUpdate: widget.isEnabled && !widget.isLocked
              ? (details) {
                  final double dragDistance = details.localOffsetFromOrigin.dy;
                  if (dragDistance < -70) {
                    if (!_isDraggingToLock) {
                      setState(() => _isDraggingToLock = true);
                      HapticUtils.vibrate();
                    }
                  } else {
                    if (_isDraggingToLock) {
                      setState(() => _isDraggingToLock = false);
                    }
                  }
                }
              : null,
          onLongPressEnd: widget.isEnabled && !widget.isLocked
              ? (_) {
                  setState(() => _isPressed = false);
                  if (_isDraggingToLock) {
                    widget.onLock();
                    setState(() => _isDraggingToLock = false);
                  } else {
                    HapticUtils.talkEnd();
                    widget.onTalkEnd();
                  }
                }
              : null,
          onLongPressCancel: widget.isEnabled && !widget.isLocked
              ? () {
                  setState(() {
                    _isPressed = false;
                    _isDraggingToLock = false;
                  });
                  HapticUtils.talkEnd();
                  widget.onTalkEnd();
                }
              : null,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: (isTalking || isReceiving)
                    ? _pulseAnimation.value
                    : _isPressed
                    ? 0.94
                    : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isTalking
                    ? AppColors.talkingGradient
                    : isReceiving
                    ? const LinearGradient(
                        colors: [AppColors.accent, AppColors.primaryLight],
                      )
                    : widget.isEnabled
                    ? AppColors.talkButtonGradient
                    : null,
                color: widget.isEnabled ? null : AppColors.surfaceLight,
                boxShadow: [
                  if (widget.isEnabled)
                    BoxShadow(
                      color:
                          (isTalking
                                  ? AppColors.accent
                                  : isReceiving
                                  ? AppColors.accent
                                  : AppColors.primary)
                              .withValues(
                                alpha: isTalking || isReceiving ? 0.6 : 0.3,
                              ),
                      blurRadius: isTalking || isReceiving ? 45 : 24,
                      spreadRadius: isTalking || isReceiving ? 10 : 0,
                    ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                          widget.isLocked
                              ? Icons.lock_rounded
                              : isReceiving
                              ? Icons.volume_up_rounded
                              : isConnecting
                              ? Icons.sync_rounded
                              : Icons.mic_rounded,
                          size: 48,
                          color: widget.isEnabled
                              ? Colors.white
                              : AppColors.textTertiary,
                        )
                        .animate(target: widget.isLocked ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                        ),
                    if (isConnecting)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    if (widget.isLocked)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'LOCKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ).animate().fadeIn().scale(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
