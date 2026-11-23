import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/tr.dart';
import '../storage/local_store.dart';

/// Device-level preferences (persisted locally, never synced in the mock).
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.bn,
    this.textScale = 1.0,
    this.highContrast = false,
    this.reducedMotion = false,
    this.banglaDigits = true,
    this.simulateOffline = false,
    this.simulateErrors = false,
    this.hideCompetitive = false,
    this.dashboardOrder = const [],
    this.hiddenWidgets = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeMode.values.byName(json['themeMode'] as String? ?? 'system'),
    language: AppLanguage.fromCode(json['language'] as String?),
    textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
    highContrast: json['highContrast'] as bool? ?? false,
    reducedMotion: json['reducedMotion'] as bool? ?? false,
    banglaDigits: json['banglaDigits'] as bool? ?? true,
    simulateOffline: json['simulateOffline'] as bool? ?? false,
    simulateErrors: json['simulateErrors'] as bool? ?? false,
    hideCompetitive: json['hideCompetitive'] as bool? ?? false,
    dashboardOrder: List<String>.from(json['dashboardOrder'] as List? ?? const []),
    hiddenWidgets: List<String>.from(json['hiddenWidgets'] as List? ?? const []),
  );

  final ThemeMode themeMode;
  final AppLanguage language;
  final double textScale;
  final bool highContrast;
  final bool reducedMotion;
  final bool banglaDigits;

  /// Developer/demo toggles that drive offline and error states across the app.
  final bool simulateOffline;
  final bool simulateErrors;

  /// Hides leaderboards and friend challenges (gamification).
  final bool hideCompetitive;
  final List<String> dashboardOrder;
  final List<String> hiddenWidgets;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    double? textScale,
    bool? highContrast,
    bool? reducedMotion,
    bool? banglaDigits,
    bool? simulateOffline,
    bool? simulateErrors,
    bool? hideCompetitive,
    List<String>? dashboardOrder,
    List<String>? hiddenWidgets,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    textScale: textScale ?? this.textScale,
    highContrast: highContrast ?? this.highContrast,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    banglaDigits: banglaDigits ?? this.banglaDigits,
    simulateOffline: simulateOffline ?? this.simulateOffline,
    simulateErrors: simulateErrors ?? this.simulateErrors,
    hideCompetitive: hideCompetitive ?? this.hideCompetitive,
    dashboardOrder: dashboardOrder ?? this.dashboardOrder,
    hiddenWidgets: hiddenWidgets ?? this.hiddenWidgets,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'language': language.name,
    'textScale': textScale,
    'highContrast': highContrast,
    'reducedMotion': reducedMotion,
    'banglaDigits': banglaDigits,
    'simulateOffline': simulateOffline,
    'simulateErrors': simulateErrors,
    'hideCompetitive': hideCompetitive,
    'dashboardOrder': dashboardOrder,
    'hiddenWidgets': hiddenWidgets,
  };
}

class AppSettingsController extends Notifier<AppSettings> {
  static const collection = 'settings';
  static const _id = 'device';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  AppSettings build() {
    final json = ref.watch(localStoreProvider).get(collection, _id);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  Future<void> update(AppSettings Function(AppSettings current) change) async {
    state = change(state);
    await _store.put(collection, _id, state.toJson());
  }

  Future<void> setThemeMode(ThemeMode mode) => update((s) => s.copyWith(themeMode: mode));

  Future<void> setLanguage(AppLanguage language) => update((s) => s.copyWith(language: language));
}

final appSettingsProvider = NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);
