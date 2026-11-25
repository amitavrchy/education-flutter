import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/tr.dart';
import '../../../auth/application/auth_controller.dart';

/// Time-of-day greeting with the user's name, shared by the dashboards (DASH-01).
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key, required this.subtitle, this.now});

  final String subtitle;

  /// Injectable clock for tests.
  final DateTime? now;

  static Tr greetingFor(DateTime t) => switch (t.hour) {
    < 5 => const Tr('শুভ রাত্রি', 'Good night'),
    < 12 => const Tr('শুভ সকাল', 'Good morning'),
    < 17 => const Tr('শুভ অপরাহ্ন', 'Good afternoon'),
    < 21 => const Tr('শুভ সন্ধ্যা', 'Good evening'),
    _ => const Tr('শুভ রাত্রি', 'Good night'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final name = auth is Authenticated ? auth.user.name.split(' ').first : '';
    final theme = Theme.of(context);
    final hello = context.tr(greetingFor(now ?? DateTime.now()));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name.isEmpty ? hello : '$hello, $name', style: theme.textTheme.headlineSmall),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Marks numbers that come from sample data until the analytics API exists.
class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({super.key});

  @override
  Widget build(BuildContext context) => Chip(label: Text(context.tr(const Tr('ডেমো ডেটা', 'Demo data'))), visualDensity: VisualDensity.compact);
}
