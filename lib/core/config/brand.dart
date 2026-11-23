import 'package:flutter/widgets.dart';

import '../l10n/tr.dart';
import 'env.dart';

/// Central branding. Changing the product name, tagline or colours happens here only.
abstract final class Brand {
  /// Working name from the product brief; override with `--dart-define=APP_NAME=…`.
  static const String name = Env.appName;
  static const Tr tagline = Tr(
    'প্রতিটি SSC ও HSC শিক্ষার্থীর জন্য বুদ্ধিমান ব্যক্তিগত টিউটর',
    'An intelligent private tutor for every SSC and HSC student',
  );
  static const Tr vision = Tr(
    'প্রতিটি শিক্ষার্থী একজন বুদ্ধিমান, সহজলভ্য ও সাশ্রয়ী ব্যক্তিগত টিউটরের যোগ্য।',
    'Every SSC and HSC student deserves an intelligent, personalized, accessible, and affordable private tutor.',
  );

  static const Color seed = Color(0xFF0F8A5F);
  static const Color accent = Color(0xFFF2A93B);
  static const String supportEmail = 'support@example.com';
}
