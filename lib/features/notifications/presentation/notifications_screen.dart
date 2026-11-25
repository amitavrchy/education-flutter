import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/notifications_controller.dart';
import '../domain/app_notification.dart';

abstract final class NotifStrings {
  static const markAll = Tr('সব পঠিত', 'Mark all read');
  static const inbox = Tr('ইনবক্স', 'Inbox');
  static const archived = Tr('আর্কাইভ', 'Archived');
  static const unreadOnly = Tr('শুধু অপঠিত', 'Unread only');
  static const archive = Tr('আর্কাইভ করো', 'Archive');
  static const unarchive = Tr('ইনবক্সে ফেরাও', 'Move to inbox');
  static const archivedDone = Tr('আর্কাইভ করা হয়েছে', 'Archived');
  static const markUnread = Tr('অপঠিত করো', 'Mark unread');
  static const open = Tr('সংশ্লিষ্ট পাতায় যাও', 'Open related page');
  static const prefs = Tr('নোটিফিকেশন পছন্দ', 'Notification preferences');
  static const detail = Tr('নোটিফিকেশন', 'Notification');
  static const notFound = Tr('নোটিফিকেশনটি আর নেই', 'This notification no longer exists');
  static const high = Tr('জরুরি', 'Urgent');
  static const type = Tr('ধরন', 'Type');
  static const received = Tr('পাওয়া গেছে', 'Received');
  static const push = Tr('পুশ', 'Push');
  static const email = Tr('ইমেইল', 'Email');
  static const show = Tr('ইনবক্সে দেখাও', 'Show in inbox');
  static const channels = Tr('ধরন অনুযায়ী চ্যানেল', 'Channels by type');
  static const pushTitle = Tr('পুশ নোটিফিকেশন', 'Push notifications');
  static const pushAsk = Tr('অনুমতি দাও', 'Allow');
  static const pushGranted = Tr('এই ডিভাইসে পুশ চালু আছে (সিমুলেটেড)', 'Push is on for this device (simulated)');
  static const pushDenied = Tr('পুশ বন্ধ — ফোনের সেটিংস থেকে চালু করো (সিমুলেটেড)', 'Push is blocked — enable it in phone settings (simulated)');
  static const pushUnknown = Tr('পরীক্ষা, রিমাইন্ডার ও মতামত সময়মতো পেতে পুশ চালু করো।', 'Turn on push to get exams, reminders and feedback on time.');
  static const pushDialog = Tr('শিক্ষাAI নোটিফিকেশন পাঠাতে চায়', 'ShikkhaAI would like to send notifications');
  static const allow = Tr('অনুমতি দাও', 'Allow');
  static const deny = Tr('না', "Don't allow");
  static const reset = Tr('অনুমতি রিসেট', 'Reset permission');
  static const quiet = Tr('রাত ১০টা–সকাল ৭টা পুশ বন্ধ', 'Quiet hours 10 pm – 7 am');
  static const digest = Tr('প্রতিটার বদলে সাপ্তাহিক ইমেইল সারাংশ', 'Weekly email digest instead of each email');
  static const simulate = Tr('ইন-অ্যাপ নোটিফিকেশন পরীক্ষা (ডেমো)', 'Try an in-app notification (demo)');
  static const simulated = Tr('ডেমো নোটিফিকেশন পাঠানো হয়েছে', 'Demo notification sent');
  static const emailNote = Tr('ইমেইল ও পুশ শুধু UI — ডেমোতে কিছু পাঠানো হয় না।', 'Email and push are UI only — nothing is sent in the demo.');
}

/// Inbox (NTF-05..11): read/unread, mark all, type filter, archive, delete, detail, deep link.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationCategory? _filter;
  bool _archived = false;
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final all = ref.watch(visibleNotificationsProvider);
    final box = [for (final n in all) if (n.archived == _archived) n];
    final items = [
      for (final n in box)
        if ((_filter == null || n.category == _filter) && (!_unreadOnly || !n.read)) n,
    ];
    final present = {for (final n in box) n.category};
    final hasUnread = box.any((n) => !n.read);
    return AppPageScaffold(
      title: context.tr(S.notifications),
      showShortcuts: false,
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        if (hasUnread && !_archived)
          TextButton(onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(role: role), child: Text(context.tr(NotifStrings.markAll))),
        IconButton(
          key: const Key('notif.prefs'),
          tooltip: context.tr(NotifStrings.prefs),
          icon: const Icon(Icons.tune),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationPrefsScreen())),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(context.tr(NotifStrings.inbox)), icon: const Icon(Icons.inbox_outlined)),
                      ButtonSegment(value: true, label: Text(context.tr(NotifStrings.archived)), icon: const Icon(Icons.archive_outlined)),
                    ],
                    selected: {_archived},
                    onSelectionChanged: (s) => setState(() {
                      _archived = s.first;
                      _filter = null;
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  key: const Key('notif.unread'),
                  label: Text(context.tr(NotifStrings.unreadOnly)),
                  selected: _unreadOnly,
                  onSelected: (v) => setState(() => _unreadOnly = v),
                ),
              ],
            ),
          ),
          ChoiceChipBar<NotificationCategory?>(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            options: [null, for (final c in NotificationCategory.values) if (present.contains(c)) c],
            selected: _filter,
            labelOf: (c) => context.tr(c?.label ?? S.all),
            onSelected: (c) => setState(() => _filter = c),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyState(icon: _archived ? Icons.archive_outlined : Icons.notifications_none, title: context.tr(S.emptyTitle))
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
      // Swipe left: delete. Swipe right: archive / unarchive.
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: context.colors.secondaryContainer, borderRadius: AppRadius.card),
        child: Icon(item.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(color: context.palette.dangerContainer, borderRadius: AppRadius.card),
        child: Icon(Icons.delete_outline, color: context.palette.danger),
      ),
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart) {
          controller.remove(item.id);
          context.showSnack(S.deleted);
        } else {
          controller.archive(item.id, archived: !item.archived);
          context.showSnack(item.archived ? NotifStrings.unarchive : NotifStrings.archivedDone);
        }
      },
      child: TapCard(
        key: Key('notif.${item.id}'),
        selected: !item.read,
        semanticLabel: '${context.tr(item.title)}. ${context.tr(item.body)}',
        onTap: () {
          controller.markRead(item.id);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NotificationDetailScreen(id: item.id)));
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon: item.category.icon, size: 40, color: item.priority == NotificationPriority.high ? context.palette.danger : null),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(item.title), style: context.text.titleSmall?.copyWith(fontWeight: item.read ? FontWeight.w500 : FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(context.tr(item.body), style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${context.tr(item.category.label)} · ${relativeTime(item.createdAt, context.lang)}',
                    style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!item.read) Padding(padding: const EdgeInsets.only(top: 4), child: CircleAvatar(radius: 4, backgroundColor: context.colors.primary)),
          ],
        ),
      ),
    );
  }
}

/// Detail view (NTF-10) with read/unread, archive, delete and the deep link (NTF-11).
class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(notificationsProvider).where((n) => n.id == id).firstOrNull;
    final controller = ref.read(notificationsProvider.notifier);
    if (item == null) {
      return AppPageScaffold(title: context.tr(NotifStrings.detail), body: EmptyState(title: context.tr(NotifStrings.notFound), icon: Icons.notifications_off_outlined));
    }
    return AppPageScaffold(
      title: context.tr(NotifStrings.detail),
      showShortcuts: false,
      actions: [
        IconButton(
          tooltip: context.tr(S.delete),
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            if (!await showConfirmDialog(context, title: S.delete, destructive: true, confirmLabel: S.delete)) return;
            await controller.remove(item.id);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(icon: item.category.icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(context.tr(item.title), style: context.text.titleLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Pill(context.tr(item.category.label)),
              if (item.priority == NotificationPriority.high) Pill(context.tr(NotifStrings.high), tone: Tone.danger),
              if (item.archived) Pill(context.tr(NotifStrings.archived), tone: Tone.info),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.tr(item.body), style: context.text.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          KeyValueRow(context.tr(NotifStrings.received), '${shortDate(item.createdAt, context.lang)} · ${relativeTime(item.createdAt, context.lang)}'),
          const SizedBox(height: AppSpacing.xl),
          if (item.route != null)
            FilledButton.icon(
              key: const Key('notif.open'),
              onPressed: () => context.go(item.route!),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.tr(NotifStrings.open)),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await controller.markRead(item.id, read: false);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.mark_email_unread_outlined),
                  label: Text(context.tr(NotifStrings.markUnread)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('notif.archive'),
                  onPressed: () async {
                    await controller.archive(item.id, archived: !item.archived);
                    if (context.mounted) context.showSnack(item.archived ? NotifStrings.unarchive : NotifStrings.archivedDone);
                  },
                  icon: Icon(item.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
                  label: Text(context.tr(item.archived ? NotifStrings.unarchive : NotifStrings.archive)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Preferences (NTF-12..15): push permission flow, per-type push/email/inbox, quiet hours,
/// digest and an in-app simulation.
class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final c = ref.read(notificationPrefsProvider.notifier);
    final role = ref.watch(currentRoleProvider);
    final (pushMsg, pushTone) = switch (prefs.pushPermission) {
      PushPermission.granted => (NotifStrings.pushGranted, Tone.success),
      PushPermission.denied => (NotifStrings.pushDenied, Tone.warning),
      PushPermission.unknown => (NotifStrings.pushUnknown, Tone.info),
    };
    return AppPageScaffold(
      title: context.tr(NotifStrings.prefs),
      showShortcuts: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(
            title: context.tr(NotifStrings.pushTitle),
            message: context.tr(pushMsg),
            tone: pushTone,
            icon: Icons.notifications_active_outlined,
            action: prefs.pushPermission == PushPermission.unknown
                ? TextButton(
                    key: const Key('notif.allowPush'),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(ctx.tr(NotifStrings.pushDialog)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr(NotifStrings.deny))),
                            FilledButton(key: const Key('notif.allowDialog'), onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr(NotifStrings.allow))),
                          ],
                        ),
                      );
                      if (ok != null) await c.setPermission(ok ? PushPermission.granted : PushPermission.denied);
                    },
                    child: Text(context.tr(NotifStrings.pushAsk)),
                  )
                : TextButton(onPressed: () => c.setPermission(PushPermission.unknown), child: Text(context.tr(NotifStrings.reset))),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr(NotifStrings.quiet)),
            value: prefs.quietHours,
            onChanged: prefs.pushPermission == PushPermission.granted ? c.setQuietHours : null,
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(context.tr(NotifStrings.digest)), value: prefs.digest, onChanged: c.setDigest),
          SectionHeader(title: context.tr(NotifStrings.channels)),
          for (final cat in NotificationCategory.values)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(cat.icon, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(context.tr(cat.label), style: context.text.titleSmall)),
                        Text(context.tr(NotifStrings.show), style: context.text.labelSmall),
                        Switch(key: Key('notif.show.${cat.name}'), value: !prefs.mutedOn(cat), onChanged: (v) => c.setMuted(cat, !v)),
                      ],
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        FilterChip(
                          label: Text(context.tr(NotifStrings.push)),
                          selected: prefs.pushOn(cat),
                          onSelected: prefs.pushPermission == PushPermission.granted && !prefs.mutedOn(cat) ? (v) => c.setPush(cat, v) : null,
                        ),
                        FilterChip(
                          label: Text(context.tr(NotifStrings.email)),
                          selected: prefs.emailOn(cat),
                          onSelected: prefs.mutedOn(cat) ? null : (v) => c.setEmail(cat, v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Text(context.tr(NotifStrings.emailNote), style: context.text.bodySmall),
          SectionHeader(title: context.tr(NotifStrings.simulate)),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final cat in NotificationCategory.values)
                ActionChip(
                  key: Key('notif.sim.${cat.name}'),
                  avatar: Icon(cat.icon, size: 18),
                  label: Text(context.tr(cat.label)),
                  onPressed: () async {
                    await ref.read(notificationsProvider.notifier).simulate(cat, role: role);
                    if (context.mounted) context.showSnack(NotifStrings.simulated, action: SnackBarAction(label: context.tr(S.notifications), onPressed: () => context.push(AppRoutes.notifications)));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
