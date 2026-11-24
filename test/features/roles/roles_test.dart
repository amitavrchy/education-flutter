import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/exams/application/exam_controller.dart';
import 'package:shikkhaai_mobile/features/exams/domain/exam.dart';
import 'package:shikkhaai_mobile/features/parent/parent_screens.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_data.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_screens.dart';

import '../../helpers/test_app.dart';

void main() {
  test('teacher reviews a submission with final marks and feedback', () async {
    final c = testContainer();
    final t = c.read(teacherProvider);
    final s = t.pending.first;
    await c.read(teacherProvider.notifier).review(s.id, 8, 'Good');
    final after = c.read(teacherProvider);
    expect(after.pending.length, t.pending.length - 1);
    expect(after.submissions.firstWhere((x) => x.id == s.id).finalMarks, 8);
  });

  testWidgets('teacher publishes a quiz that students then see', (tester) async {
    late ExamState Function() exams;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      exams = () => ref.read(examProvider);
      return const TeacherExamsScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    final before = exams().templates.where((t) => t.type == ExamType.teacherAssigned).length;
    await tester.ensureVisible(find.byKey(const Key('exam.publish')));
    await tester.tap(find.byKey(const Key('exam.publish')));
    await tester.pumpAndSettle();
    expect(exams().templates.where((t) => t.type == ExamType.teacherAssigned).length, before + 1);
  });

  testWidgets('teacher home and evaluation queue render live data', (tester) async {
    await tester.pumpWidget(testApp(const TeacherHomeScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('To review'), findsOneWidget);
    await tester.pumpWidget(testApp(const TeacherEvaluationScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sub.sub-0')), findsOneWidget);
  });

  testWidgets('parent sees "not shared" when the student hides scores', (tester) async {
    late void Function() hide;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      hide = () => ref.read(accountProvider.notifier).setPrivacy('scores', false);
      return const ParentResultsScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    hide();
    await tester.pumpAndSettle();
    expect(find.text('Your child has not shared this'), findsOneWidget);
  });

  testWidgets('parent links a child with the demo code', (tester) async {
    await tester.pumpWidget(testApp(const ParentChildrenScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('link.phone')), '01712345678');
    await tester.tap(find.byKey(const Key('link.go')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('link.code')), '123456');
    await tester.tap(find.byKey(const Key('link.go')));
    await tester.pumpAndSettle();
    expect(find.textContaining('(ডেমো)'), findsOneWidget);
  });
}
