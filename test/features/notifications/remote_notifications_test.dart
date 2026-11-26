import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';
import 'package:shikkhaai_mobile/features/notifications/application/notifications_controller.dart';
import 'package:shikkhaai_mobile/features/notifications/data/remote_notifications.dart';
import 'package:shikkhaai_mobile/features/notifications/domain/app_notification.dart';
import 'package:dio/dio.dart';

import '../../helpers/test_app.dart';

class _FakeRemote extends RemoteNotifications {
  _FakeRemote() : super(ApiClient(Dio()));

  final List<String> calls = [];

  @override
  Future<List<AppNotification>> all() async => [
    RemoteNotifications.fromJson({'id': 'ntf-1', 'type': 'exam_result', 'title': 'Result', 'body': '80%', 'href': '/student/exams/results/a1', 'portal': 'student', 'read': false, 'archived': false, 'priority': 'high', 'createdAt': DateTime.now().toIso8601String()}),
  ];

  @override
  Future<void> update(String id, {bool? read, bool? archived}) async => calls.add('update $id $read $archived');

  @override
  Future<void> markAllRead(String? portal) async => calls.add('readAll $portal');
}

void main() {
  test('backend types and web links map onto app categories and routes', () {
    expect(RemoteNotifications.categoryOf('new_assignment'), NotificationCategory.assignment);
    expect(RemoteNotifications.categoryOf('curriculum_update'), NotificationCategory.announcement);
    expect(RemoteNotifications.routeOf('/student/exams/results/x'), '/student/practice/exams');
    expect(RemoteNotifications.routeOf('/teacher/review/rv-1'), '/teacher-review');
    expect(RemoteNotifications.routeOf('/nowhere'), isNull);
  });

  test('API mode: server inbox replaces the demo seed; actions call the server', () async {
    final fake = _FakeRemote();
    final c = testContainer(overrides: [remoteNotificationsProvider.overrideWithValue(fake)]);
    c.read(notificationsProvider);
    await c.read(notificationsProvider.notifier).refresh();
    final items = c.read(notificationsProvider);
    expect(items.map((n) => n.id), ['ntf-1']);
    expect(items.single.priority, NotificationPriority.high);
    await c.read(notificationsProvider.notifier).markRead('ntf-1');
    await c.read(notificationsProvider.notifier).markAllRead(role: 'student');
    expect(fake.calls, ['update ntf-1 true null', 'readAll student']);
    expect(c.read(notificationsProvider).single.read, isTrue);
  });
}
