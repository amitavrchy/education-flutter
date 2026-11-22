import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';

/// Shown while the saved session is restored; the router moves on automatically.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(AppConstants.appNameBn, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
