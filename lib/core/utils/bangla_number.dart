const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Converts ASCII digits to Bangla digits: `2026` → `২০২৬`.
String toBanglaDigits(Object value) =>
    value.toString().replaceAllMapped(RegExp(r'\d'), (match) => _banglaDigits[int.parse(match[0]!)]);

/// Converts Bangla digits back to ASCII, e.g. for user-typed phone numbers.
String toAsciiDigits(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final index = _banglaDigits.indexOf(char);
    buffer.write(index >= 0 ? index : char);
  }
  return buffer.toString();
}
