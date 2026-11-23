import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../application/notifications_controller.dart';
import '../domain/app_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(notificationsProvider);
    final items = _filter == null ? all : all.where((n) => n.category == _filter).toList();
    final hasUnread = all.any((n) => !n.read);
    return AppPageScaffold(
      title: context.tr(S.notifications),
      showShortcuts: false,
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        if (hasUnread)
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: Text(context.tr(const Tr('সব পঠিত', 'Mark all read'))),
          ),
      ],
      body: Column(
        children: [
          ChoiceChipBar<NotificationCategory?>(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            options: [null, ...NotificationCategory.values],
            selected: _filter,
            labelOf: (c) => context.tr(c?.label ?? S.all),
            onSelected: (c) => setState(() => _filter = c),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(
                    icon: Icons.notifications_none,
                    title: context.tr(S.emptyTitle),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _NotificationTile(item: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(notificationsProvider.notifier);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: context.palette.dangerContainer, borderRadius: AppRadius.card),
        child: Icon(Icons.delete_outline, color: context.palette.danger),
      ),
      onDismissed: (_) {
        controller.remove(item.id);
        context.showSnack(S.deleted);
      },
      child: TapCard(
        selected: !item.read,
        semanticLabel: '${context.tr(item.title)}. ${context.tr(item.body)}',
        onTap: () {
          controller.markRead(item.id);
          if (item.route != null) context.go(item.route!);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: item.category.icon, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(item.title),
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(context.tr(item.body), style: context.text.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    relativeTime(item.createdAt, context.lang),
                    style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
