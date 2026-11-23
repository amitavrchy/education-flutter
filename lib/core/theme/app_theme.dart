import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../config/brand.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 themes (light, dark, each with an optional high-contrast variant).
///
/// Typography uses Hind Siliguri, which covers Bangla and Latin glyphs, with a taller line
/// height for Bangla readability. Fonts are fetched by google_fonts and cached.
abstract final class AppTheme {
  static ThemeData light({bool useGoogleFonts = true, bool highContrast = false}) =>
      _build(Brightness.light, useGoogleFonts: useGoogleFonts, highContrast: highContrast);

  static ThemeData dark({bool useGoogleFonts = true, bool highContrast = false}) =>
      _build(Brightness.dark, useGoogleFonts: useGoogleFonts, highContrast: highContrast);

  static ThemeData _build(
    Brightness brightness, {
    required bool useGoogleFonts,
    required bool highContrast,
  }) {
    final dark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: Brand.seed,
      brightness: brightness,
      contrastLevel: highContrast ? 1.0 : 0.0,
    );
    // Neutral, slightly cool surfaces instead of tinted green ones.
    if (!highContrast) {
      scheme = scheme.copyWith(
        surface: dark ? const Color(0xFF111416) : const Color(0xFFF8FAF9),
        surfaceContainerLowest: dark ? const Color(0xFF0C0F10) : Colors.white,
        surfaceContainerLow: dark ? const Color(0xFF171B1D) : Colors.white,
        surfaceContainer: dark ? const Color(0xFF1C2123) : const Color(0xFFF1F4F3),
        surfaceContainerHigh: dark ? const Color(0xFF232829) : const Color(0xFFEAEFED),
        surfaceContainerHighest: dark ? const Color(0xFF2B3133) : const Color(0xFFE2E8E6),
        outlineVariant: dark ? const Color(0xFF30383A) : const Color(0xFFDDE4E1),
      );
    }

    final base = ThemeData(colorScheme: scheme, brightness: brightness, useMaterial3: true);
    var textTheme = useGoogleFonts ? GoogleFonts.hindSiliguriTextTheme(base.textTheme) : base.textTheme;
    textTheme = textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
      titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: textTheme.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
      labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
    textTheme = textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.field,
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.field);
    const buttonSize = Size(64, 48);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [AppPalette.of(brightness, highContrast: highContrast)],
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: highContrast ? scheme.outline : scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize, shape: buttonShape, textStyle: textTheme.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: buttonSize, shape: buttonShape, textStyle: textTheme.labelLarge),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape, textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chip),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl))),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.field),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: scheme.outlineVariant,
        tabAlignment: TabAlignment.start,
      ),
    );
  }
}
