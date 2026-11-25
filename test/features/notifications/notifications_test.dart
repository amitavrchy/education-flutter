import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/notifications/application/notifications_controller.dart';
import 'package:shikkhaai_mobile/features/notifications/domain/app_notification.dart';
import 'package:shikkhaai_mobile/features/notifications/presentation/notifications_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  test('inbox is filtered by role', () {
    final all = [
      for (final n in testContainer().read(notificationsProvider)) n,
    ];
    expect(all.where((n) => n.isFor('parent')).every((n) => n.audience == null || n.audience == 'parent'), isTrue);
    expect(all.where((n) => n.isFor('teacher')).any((n) => n.audience == 'student'), isFalse);
  });

  test('archive, mark unread and mute', () async {
    final c = testContainer();
    final ctl = c.read(notificationsProvider.notifier);
    final first = c.read(notificationsProvider).first;
    await ctl.archive(first.id);
    expect(c.read(notificationsProvider).firstWhere((n) => n.id == first.id).archived, isTrue);
    await ctl.markRead(first.id, read: false);
    expect(c.read(notificationsProvider).firstWhere((n) => n.id == first.id).read, isFalse);
    final before = c.read(visibleNotificationsProvider).length;
    await c.read(notificationPrefsProvider.notifier).setMuted(first.category, true);
    expect(c.read(visibleNotificationsProvider).length, lessThan(before));
  });

  test('push channel needs the simulated permission', () async {
    final c = testContainer();
    expect(c.read(notificationPrefsProvider).pushOn(NotificationCategory.exam), isFalse);
    await c.read(notificationPrefsProvider.notifier).setPermission(PushPermission.granted);
    expect(c.read(notificationPrefsProvider).pushOn(NotificationCategory.exam), isTrue);
  });

  test('simulation adds an unread notification', () async {
    final c = testContainer();
    final unread = c.read(unreadNotificationCountProvider);
    await c.read(notificationsProvider.notifier).simulate(NotificationCategory.assignment);
    expect(c.read(unreadNotificationCountProvider), unread + 1);
  });

  testWidgets('tapping opens the detail view, which archives', (tester) async {
    await tester.pumpWidget(testApp(const NotificationsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notif.n1')));
    await tester.pumpAndSettle();
    expect(find.text('Open related page'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notif.archive')));
    await tester.pumpAndSettle();
    expect(find.text('Move to inbox'), findsOneWidget);
  });

  testWidgets('preferences grant push through the permission dialog', (tester) async {
    await tester.pumpWidget(testApp(const NotificationPrefsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notif.allowPush')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notif.allowDialog')));
    await tester.pumpAndSettle();
    expect(find.text('Push is on for this device (simulated)'), findsOneWidget);
  });
}
