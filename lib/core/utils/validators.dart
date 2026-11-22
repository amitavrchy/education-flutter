import 'bangla_number.dart';

/// Form validators returning a Bangla error message, or null when valid.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _bdPhone = RegExp(r'^(?:\+?88)?01[3-9]\d{8}$');

  static bool isEmail(String value) => _email.hasMatch(value.trim());

  /// Accepts 01XXXXXXXXX, 8801XXXXXXXXX or +8801XXXXXXXXX, in ASCII or Bangla digits.
  static bool isBdPhone(String value) =>
      _bdPhone.hasMatch(toAsciiDigits(value).replaceAll(RegExp(r'[\s-]'), ''));

  static String? identifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'ইমেইল বা মোবাইল নম্বর দিন';
    if (!isEmail(input) && !isBdPhone(input)) return 'সঠিক ইমেইল বা মোবাইল নম্বর দিন';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'পাসওয়ার্ড দিন';
    if (value.length < 8) return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
    return null;
  }
}
