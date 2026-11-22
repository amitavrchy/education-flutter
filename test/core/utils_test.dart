import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/utils/bangla_number.dart';
import 'package:shikkhaai_mobile/core/utils/validators.dart';

void main() {
  group('Bangla digits', () {
    test('converts both ways', () {
      expect(toBanglaDigits(2026), '২০২৬');
      expect(toBanglaDigits('78%'), '৭৮%');
      expect(toAsciiDigits('০১৭১২৩৪৫৬৭৮'), '01712345678');
    });
  });

  group('Validators', () {
    test('accepts email and Bangladeshi phone numbers', () {
      expect(Validators.identifier('student@shikkha.ai'), isNull);
      expect(Validators.identifier('01712345678'), isNull);
      expect(Validators.identifier('+8801712345678'), isNull);
      expect(Validators.identifier('০১৭১২৩৪৫৬৭৮'), isNull);
    });

    test('rejects empty and malformed identifiers', () {
      expect(Validators.identifier(''), isNotNull);
      expect(Validators.identifier('01212345678'), isNotNull);
      expect(Validators.identifier('not-an-email'), isNotNull);
    });

    test('requires a password of at least 8 characters', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('long-enough'), isNull);
    });
  });
}
