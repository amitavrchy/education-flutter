import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/mock/mock_simulator.dart';
import 'package:shikkhaai_mobile/core/storage/local_store.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/core/storage/token_storage.dart';
import 'package:shikkhaai_mobile/core/theme/app_theme.dart';

/// In-memory replacement for secure storage (no platform channel in tests).
class MemoryTokenStorage extends TokenStorage {
  final Map<String, String?> _values = {};

  @override
  Future<String?> readAccessToken() async => _values['access'];

  @override
  Future<String?> readRefreshToken() async => _values['refresh'];

  @override
  Future<String?> readUserJson() async => _values['user'];

  @override
  Future<void> saveSession({required String accessToken, String? refreshToken, required String userJson}) async {
    _values
      ..['access'] = accessToken
      ..['refresh'] = refreshToken
      ..['user'] = userJson;
  }

  @override
  Future<void> clear() async => _values.clear();
}

/// Provider container for unit tests: in-memory store, no mock latency.
ProviderContainer testContainer({LocalStore? store, List<dynamic> overrides = const []}) => ProviderContainer(
  retry: (_, _) => null,
  overrides: [
    localStoreProvider.overrideWithValue(store ?? MemoryLocalStore()),
    mockLatencyProvider.overrideWithValue(Duration.zero),
    tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
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
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
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
