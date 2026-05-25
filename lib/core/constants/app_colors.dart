import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette — vibrant purple-blue
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);

  // Accent — electric cyan
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentSoft = Color(0xFF80F0FF);

  // Surface colors — dark mode
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);
  static const Color surfaceElevated = Color(0xFF30363D);

  // Text
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF484F58);

  // Status
  static const Color online = Color(0xFF3FB950);
  static const Color offline = Color(0xFF484F58);
  static const Color talking = Color(0xFF6C63FF);
  static const Color error = Color(0xFFF85149);
  static const Color warning = Color(0xFFD29922);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient talkButtonGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient talkingGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF161B22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
