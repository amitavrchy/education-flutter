import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../auth/application/auth_controller.dart';

/// "Assalamu alaikum, <name>" header shared by the dashboards.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final name = auth is Authenticated ? auth.user.name : '';
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('স্বাগতম, $name', style: theme.textTheme.headlineSmall),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Marks numbers that come from sample data until the analytics API exists.
class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({super.key});

  @override
  Widget build(BuildContext context) =>
      const Chip(label: Text('ডেমো ডেটা'), visualDensity: VisualDensity.compact);
}
