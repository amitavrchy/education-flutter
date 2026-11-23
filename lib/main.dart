import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/network/network_providers.dart';
import 'core/storage/local_store.dart';
import 'features/auth/application/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final store = await HiveLocalStore.open();
  runApp(
    ProviderScope(
      // Riverpod 3 retries failing providers by default; mock errors must surface immediately.
      retry: (retryCount, error) => null,
      overrides: [
        localStoreProvider.overrideWithValue(store),
        // A 401 from any API call signs the user out (core/ stays independent of features/).
        unauthorizedHandlerProvider.overrideWith(
          (ref) => () => ref.read(authControllerProvider.notifier).onUnauthorized(),
        ),
      ],
      child: const ShikkhaApp(),
    ),
  );
}
