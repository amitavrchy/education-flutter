import 'package:flutter/widgets.dart';

import '../utils/bangla_number.dart';

/// Languages the UI ships in. Bangla is the default.
enum AppLanguage {
  bn(Locale('bn', 'BD'), 'বাংলা'),
  en(Locale('en', 'US'), 'English');

  const AppLanguage(this.locale, this.nativeName);

  final Locale locale;
  final String nativeName;

  static AppLanguage fromCode(String? code) => code == 'en' ? AppLanguage.en : AppLanguage.bn;
}

/// A translatable string: one entry of the translation dictionary.
///
/// UI strings are declared once in a dictionary class (see `common_strings.dart` and each
/// feature's `*_strings.dart`) and resolved with `S.save(context)` or `context.tr(...)`.
/// Content records use the same type for bilingual fields (`{ "bn": …, "en": … }` in JSON).
@immutable
class Tr {
  const Tr(this.bn, this.en);

  /// Same text in both languages (proper nouns, formulas, codes).
  const Tr.same(String text) : bn = text, en = text;

  factory Tr.fromJson(Object? json) {
    if (json is String) return Tr.same(json);
    if (json is Map) {
      final bn = json['bn'] as String? ?? json['en'] as String? ?? '';
      return Tr(bn, json['en'] as String? ?? bn);
    }
    return const Tr.same('');
  }

  final String bn;
  final String en;

  String of(AppLanguage language) => language == AppLanguage.en ? en : bn;

  String call(BuildContext context) => of(context.lang);

  /// Replaces `{name}` placeholders in both languages.
  Tr fill(Map<String, Object> values) {
    String apply(String text, bool bangla) {
      var out = text;
      values.forEach((key, value) {
        final rendered = bangla && value is num ? toBanglaDigits(value) : value.toString();
        out = out.replaceAll('{$key}', rendered);
      });
      return out;
    }

    return Tr(apply(bn, true), apply(en, false));
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || bn.toLowerCase().contains(q) || en.toLowerCase().contains(q);
  }

  Map<String, dynamic> toJson() => {'bn': bn, 'en': en};

  @override
  bool operator ==(Object other) => other is Tr && other.bn == bn && other.en == en;

  @override
  int get hashCode => Object.hash(bn, en);

  @override
  String toString() => en;
}

extension TrContext on BuildContext {
  AppLanguage get lang => AppLanguage.fromCode(Localizations.maybeLocaleOf(this)?.languageCode);

  bool get isBangla => lang == AppLanguage.bn;

  String tr(Tr text) => text.of(lang);

  /// Numbers in the active script: ৪২ in Bangla, 42 in English.
  String n(Object value) => isBangla && NumeralScope.banglaDigitsOf(this) ? toBanglaDigits(value) : value.toString();

  String pct(num value) => '${n(value.round())}%';
}

/// Carries the "Bangla numerals" preference down the tree so [TrContext.n] can honour it.
class NumeralScope extends InheritedWidget {
  const NumeralScope({super.key, required this.banglaDigits, required super.child});

  final bool banglaDigits;

  static bool banglaDigitsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NumeralScope>()?.banglaDigits ?? true;

  @override
  bool updateShouldNotify(NumeralScope oldWidget) => oldWidget.banglaDigits != banglaDigits;
}
