import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_spacing.dart';

/// KPI tile for dashboards.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column grid of StatCards that sizes to its content.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.cards});

  final List<StatCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [for (final card in cards) SizedBox(width: width, child: card)],
        );
      },
    );
  }
}
