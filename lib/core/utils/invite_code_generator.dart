import 'dart:math';

class InviteCodeGenerator {
  InviteCodeGenerator._();

  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  /// Generates a 6-character invite code.
  /// Excludes ambiguous characters (I, O, 0, 1) for readability.
  static String generate() {
    return List.generate(
      6,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
  }

  /// Validates invite code format.
  static bool isValid(String code) {
    if (code.length != 6) return false;
    return code.split('').every((c) => _chars.contains(c.toUpperCase()));
  }

  /// Formats code with a dash for display: "ABC-DEF"
  static String format(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)}-${code.substring(3)}';
  }
}
