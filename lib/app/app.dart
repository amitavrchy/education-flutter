import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/env.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import 'router/app_router.dart';

class ShikkhaApp extends ConsumerWidget {
  const ShikkhaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useGoogleFonts = ref.watch(useGoogleFontsProvider);
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
      darkTheme: AppTheme.dark(useGoogleFonts: useGoogleFonts),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      // Bangla first; framework strings (date pickers, tooltips…) are localized too.
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
