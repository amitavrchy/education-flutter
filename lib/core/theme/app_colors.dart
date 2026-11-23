import 'package:material_ui/material_ui.dart';

/// Raw brand and semantic colours. Widgets read them through [AppPalette] so light,
/// dark and high-contrast themes stay consistent.
abstract final class AppColors {
  static const Color brandGreen = Color(0xFF0F8A5F);
  static const Color brandRed = Color(0xFFD7263D);
  static const Color amber = Color(0xFFF2A93B);

  static const Color success = Color(0xFF1E9E5A);
  static const Color warning = Color(0xFFE0A100);
  static const Color info = Color(0xFF2F7BE0);
  static const Color danger = Color(0xFFD64545);

  /// Categorical palette for subjects and chart series (colour-blind aware order).
  static const List<Color> categorical = [
    Color(0xFF2F7BE0),
    Color(0xFF0F8A5F),
    Color(0xFFE07A2F),
    Color(0xFF8A4FD8),
    Color(0xFFD64575),
    Color(0xFF1AA3A3),
    Color(0xFFB08A12),
    Color(0xFF5C6BC0),
  ];
}

/// Semantic colours as a theme extension: `context.palette.success`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.danger,
    required this.dangerContainer,
    required this.streak,
    required this.xp,
  });

  factory AppPalette.of(Brightness brightness, {bool highContrast = false}) {
    final dark = brightness == Brightness.dark;
    Color tone(Color base, double amount) =>
        Color.lerp(base, dark ? Colors.black : Colors.white, amount)!;
    return AppPalette(
      success: dark ? const Color(0xFF6FD39B) : (highContrast ? const Color(0xFF0B5E33) : const Color(0xFF15804A)),
      successContainer: tone(AppColors.success, dark ? 0.7 : 0.85),
      warning: dark ? const Color(0xFFF5C451) : const Color(0xFF9A6B00),
      warningContainer: tone(AppColors.warning, dark ? 0.7 : 0.85),
      info: dark ? const Color(0xFF7FB2F5) : const Color(0xFF1F63C2),
      infoContainer: tone(AppColors.info, dark ? 0.7 : 0.87),
      danger: dark ? const Color(0xFFF08A8A) : const Color(0xFFB3261E),
      dangerContainer: tone(AppColors.danger, dark ? 0.7 : 0.87),
      streak: const Color(0xFFF2762E),
      xp: const Color(0xFF8A4FD8),
    );
  }

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
  final Color danger;
  final Color dangerContainer;
  final Color streak;
  final Color xp;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
      xp: Color.lerp(xp, other.xp, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.of(Theme.of(this).brightness);
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
  bool get isWide => MediaQuery.sizeOf(this).width >= 720;
}
