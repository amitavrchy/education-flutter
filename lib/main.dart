import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/network_providers.dart';
import 'features/auth/application/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        // A 401 from any API call signs the user out (core/ stays independent of features/).
        unauthorizedHandlerProvider.overrideWith(
          (ref) => () => ref.read(authControllerProvider.notifier).onUnauthorized(),
        ),
      ],
      child: const ShikkhaApp(),
    ),
  );
}
