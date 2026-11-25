import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/network/api_exception.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/notifications/application/notifications_controller.dart';
import 'package:shikkhaai_mobile/features/parent/guardian_controller.dart';
import 'package:shikkhaai_mobile/features/parent/parent_screens.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_data.dart';

import '../../helpers/test_app.dart';

void main() {
  test('seeds two active children with the device student first', () {
    final c = testContainer();
    final g = c.read(guardianProvider);
    expect(g.active.length, 2);
    expect(g.selected!.self, isTrue);
    expect(c.read(childSummaryProvider('gl-2'))!.subjectMastery, isNotEmpty);
  });

  test('wrong link code and wrong OTP are rejected', () async {
    final c = testContainer();
    final n = c.read(guardianProvider.notifier);
    await expectLater(n.requestLink('SHK-0000', 'মা'), throwsA(isA<ApiException>()));
    final link = await n.requestLink('SHK-2741', 'মা');
    expect(link.status, LinkStatus.pending);
    await expectLater(n.confirmLink(link.id, '000000'), throwsA(isA<ApiException>()));
    await n.confirmLink(link.id, '123456');
    expect(c.read(guardianProvider).selected!.id, link.id);
  });

  test('guardian cannot turn AI-conversation sharing on', () async {
    final c = testContainer();
    await expectLater(
      c.read(guardianProvider.notifier).setPermission('gl-self', ShareKey.aiConversations, true),
      throwsA(isA<ApiException>()),
    );
    await c.read(guardianProvider.notifier).setPermission('gl-self', ShareKey.scores, false);
    expect(c.read(childSummaryProvider('gl-self'))!.can(ShareKey.scores), isFalse);
  });

  test("the student's own privacy choice wins over the guardian's switch", () async {
    final c = testContainer();
    expect(c.read(childSummaryProvider('gl-self'))!.can(ShareKey.calendar), isTrue);
    await c.read(accountProvider.notifier).setPrivacy('calendar', false);
    expect(c.read(childSummaryProvider('gl-self'))!.can(ShareKey.calendar), isFalse);
  });

  test("a teacher's review of the student's script reaches the guardian", () async {
    final c = testContainer();
    final sub = c.read(teacherProvider).pending.firstWhere((s) => s.student == selfChildName);
    await c.read(teacherProvider.notifier).review(sub.id, 9, 'চমৎকার');
    final notes = c.read(teacherNotesProvider('gl-self'));
    expect(notes.any((n) => n.message.contains('চমৎকার')), isTrue);
  });

  test('a reply lands in the teacher inbox', () async {
    final c = testContainer();
    final note = c.read(teacherNotesProvider('gl-self')).first;
    await c.read(guardianProvider.notifier).reply(note, 'ধন্যবাদ');
    expect(c.read(teacherNotesProvider('gl-self')).firstWhere((n) => n.id == note.id).reply, 'ধন্যবাদ');
    expect(c.read(notificationsProvider).any((n) => n.audience == 'teacher' && n.body.bn == 'ধন্যবাদ'), isTrue);
  });

  testWidgets('dashboard switches between children', (tester) async {
    await tester.pumpWidget(testApp(const ParentHomeScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text("This device's student — live data", findRichText: true), findsNothing);
    expect(find.textContaining("This device's student"), findsOneWidget);
    await tester.tap(find.byKey(const Key('child.gl-2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo data'), findsOneWidget);
  });

  testWidgets('guardian adds a weekly goal', (tester) async {
    await tester.pumpWidget(testApp(const ParentGoalsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal.add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goal.title')), '5 hours a week');
    await tester.enterText(find.byKey(const Key('goal.target')), '300');
    await tester.tap(find.byKey(const Key('goal.save')));
    await tester.pumpAndSettle();
    expect(find.text('5 hours a week'), findsOneWidget);
  });

  testWidgets('calendar is hidden when the student stops sharing it', (tester) async {
    late void Function() hide;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      hide = () => ref.read(accountProvider.notifier).setPrivacy('calendar', false);
      return const ParentCalendarScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    hide();
    await tester.pumpAndSettle();
    expect(find.text('Your child has not shared this'), findsOneWidget);
  });
}
