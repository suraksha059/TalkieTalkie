import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A glassmorphism-style card with blur effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.surfaceLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
