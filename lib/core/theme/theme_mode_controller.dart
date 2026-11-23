import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../settings/app_settings.dart';

/// Light / dark / system preference, persisted through [appSettingsProvider].
final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(appSettingsProvider).themeMode);

/// Tests override this with false so no network font requests are made.
final useGoogleFontsProvider = Provider<bool>((ref) => true);
