import 'package:flutter/services.dart';

class HapticUtils {
  HapticUtils._();

  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void vibrate() => HapticFeedback.vibrate();

  /// Haptic for pressing the talk button
  static void talkStart() => HapticFeedback.heavyImpact();

  /// Haptic for releasing the talk button
  static void talkEnd() => HapticFeedback.mediumImpact();

  /// Haptic for receiving a talk
  static void incomingTalk() => HapticFeedback.vibrate();
}
