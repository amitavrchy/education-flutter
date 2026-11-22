import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 light and dark themes.
///
/// Typography uses Hind Siliguri, which covers Bangla and Latin glyphs. Fonts are fetched
/// at runtime by google_fonts and cached; bundle them under assets/fonts for offline-first builds.
abstract final class AppTheme {
  static ThemeData light({bool useGoogleFonts = true}) =>
      _build(Brightness.light, useGoogleFonts: useGoogleFonts);

  static ThemeData dark({bool useGoogleFonts = true}) =>
      _build(Brightness.dark, useGoogleFonts: useGoogleFonts);

  static ThemeData _build(Brightness brightness, {required bool useGoogleFonts}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandGreen,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: colorScheme, brightness: brightness);

    final textTheme = useGoogleFonts
        ? GoogleFonts.hindSiliguriTextTheme(base.textTheme)
        : base.textTheme;

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
