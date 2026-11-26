import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/env.dart';
import '../core/l10n/tr.dart';
import '../core/settings/app_settings.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/curriculum/presentation/catalog_gate.dart';
import 'router/app_router.dart';

class ShikkhaApp extends ConsumerWidget {
  const ShikkhaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useGoogleFonts = ref.watch(useGoogleFontsProvider);
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(useGoogleFonts: useGoogleFonts, highContrast: settings.highContrast),
      darkTheme: AppTheme.dark(useGoogleFonts: useGoogleFonts, highContrast: settings.highContrast),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      // Bangla first; framework strings (date pickers, tooltips…) follow the chosen language.
      locale: settings.language.locale,
      supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // In-app accessibility settings layer on top of the OS ones.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(media.textScaler.scale(1) * settings.textScale),
            disableAnimations: media.disableAnimations || settings.reducedMotion,
          ),
          child: NumeralScope(banglaDigits: settings.banglaDigits, child: CatalogGate(child: child!)),
        );
      },
    );
  }
}
