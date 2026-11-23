import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/mock/mock_simulator.dart';
import 'package:shikkhaai_mobile/core/storage/local_store.dart';
import 'package:shikkhaai_mobile/core/theme/app_theme.dart';

/// Provider container for unit tests: in-memory store, no mock latency.
ProviderContainer testContainer({LocalStore? store, List<dynamic> overrides = const []}) => ProviderContainer(
  retry: (_, _) => null,
  overrides: [
    localStoreProvider.overrideWithValue(store ?? MemoryLocalStore()),
    mockLatencyProvider.overrideWithValue(Duration.zero),
    ...overrides.cast(),
  ],
);

/// Wraps [child] in a ProviderScope + themed MaterialApp (Bangla by default).
Widget testApp(Widget child, {LocalStore? store, AppLanguage lang = AppLanguage.bn, List<dynamic> overrides = const []}) =>
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        localStoreProvider.overrideWithValue(store ?? MemoryLocalStore()),
        mockLatencyProvider.overrideWithValue(Duration.zero),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: AppTheme.light(useGoogleFonts: false),
        locale: lang.locale,
        supportedLocales: const [Locale('bn', 'BD'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
      ),
    );
