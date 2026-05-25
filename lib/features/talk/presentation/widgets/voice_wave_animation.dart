import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated voice wave visualization shown during active talk sessions.
class VoiceWaveAnimation extends StatefulWidget {
  const VoiceWaveAnimation({super.key});

  @override
  State<VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<VoiceWaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 200,
      child: AnimatedBuilder(
        listenable: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavePainter(
              progress: _controller.value,
              color: AppColors.primary,
            ),
            size: const Size(200, 60),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = size.height / 2;
    final barCount = 20;
    final barWidth = size.width / barCount;

    for (var i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final normalizedI = i / barCount;

      // Create wave pattern
      final wave = sin((normalizedI * 2 * pi) + (progress * 2 * pi));
      final wave2 = sin((normalizedI * 3 * pi) + (progress * 2 * pi * 1.5));
      final amplitude = (wave * 0.6 + wave2 * 0.4).abs();

      final barHeight = 4 + amplitude * (size.height * 0.4);

      // Gradient color based on position
      final t = normalizedI;
      final barColor = Color.lerp(
        AppColors.primary,
        AppColors.accent,
        t,
      )!
          .withValues(alpha: 0.5 + amplitude * 0.5);

      paint.color = barColor;

      canvas.drawLine(
        Offset(x, center - barHeight),
        Offset(x, center + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// AnimatedBuilder widget.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
