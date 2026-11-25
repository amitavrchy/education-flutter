import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/network/api_exception.dart';
import 'package:shikkhaai_mobile/features/curriculum/domain/curriculum_models.dart';
import 'package:shikkhaai_mobile/features/notifications/application/notifications_controller.dart';
import 'package:shikkhaai_mobile/features/question_bank/domain/question.dart';
import 'package:shikkhaai_mobile/features/teacher/review_data.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_data.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_screens.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_workflow_screens.dart';

import '../../helpers/test_app.dart';

Question _q(String id) => Question(
  id: id,
  subjectId: 'ssc-phy',
  chapterId: 'c',
  topicId: 't',
  type: QuestionType.short,
  difficulty: Difficulty.easy,
  marks: 2,
  stem: const Tr.same('বেগ কাকে বলে?'),
  answer: const Tr.same('একক সময়ে সরণ'),
);

void main() {
  test('role permissions: teachers cannot approve, reviewers cannot publish', () {
    expect(allowedTransitions(ContentStatus.inReview, ActorRole.teacher), isEmpty);
    expect(allowedTransitions(ContentStatus.inReview, ActorRole.reviewer), containsAll([ContentStatus.approved, ContentStatus.changesRequested]));
    expect(allowedTransitions(ContentStatus.approved, ActorRole.reviewer), isNot(contains(ContentStatus.published)));
    expect(allowedTransitions(ContentStatus.approved, ActorRole.manager), contains(ContentStatus.published));
  });

  test('reviewer flow: start → request changes needs a note → teacher resubmits', () async {
    final c = testContainer();
    final r = c.read(reviewProvider.notifier);
    final item = c.read(reviewProvider).items.firstWhere((i) => i.status == ContentStatus.submitted);
    await expectLater(r.transition(item.id, ContentStatus.inReview), throwsA(isA<ApiException>()));
    await r.actAs(ActorRole.reviewer);
    await r.transition(item.id, ContentStatus.inReview);
    await expectLater(r.transition(item.id, ContentStatus.changesRequested), throwsA(isA<ApiException>()));
    await r.transition(item.id, ContentStatus.changesRequested, note: 'একক যোগ করুন');
    expect(c.read(notificationsProvider).first.audience, 'teacher');
    await r.actAs(ActorRole.teacher);
    await r.transition(item.id, ContentStatus.submitted);
    final after = c.read(reviewProvider).item(item.id)!;
    expect(after.status, ContentStatus.submitted);
    expect(after.history.map((e) => e.to), containsAllInOrder([ContentStatus.inReview, ContentStatus.changesRequested, ContentStatus.submitted]));
  });

  test('accepting a suggestion rewrites the content', () async {
    final c = testContainer();
    final item = c.read(reviewProvider).items.firstWhere((i) => i.kind == ReviewKind.aiAnswer);
    final sg = item.suggestions.first;
    await c.read(reviewProvider.notifier).resolveSuggestion(item.id, sg.id, accept: true);
    final after = c.read(reviewProvider).item(item.id)!;
    expect(after.preview, contains(sg.to));
    expect(after.suggestions.first.state, SuggestionState.accepted);
    await expectLater(c.read(reviewProvider.notifier).suggest(item.id, 'নেই এমন লেখা', 'x'), throwsA(isA<ApiException>()));
  });

  test('authored question keeps one review item and bumps the version', () async {
    final c = testContainer();
    final r = c.read(reviewProvider.notifier);
    await r.saveQuestion(_q('tq-1'), submit: false);
    await r.saveQuestion(_q('tq-1'), submit: true);
    final s = c.read(reviewProvider);
    expect(s.questions.single.version, 2);
    expect(s.questions.single.status, ContentStatus.submitted);
    expect(s.items.where((i) => i.contentId == 'tq-1').length, 1);
    await r.actAs(ActorRole.reviewer);
    final id = s.items.firstWhere((i) => i.contentId == 'tq-1').id;
    await r.transition(id, ContentStatus.inReview);
    expect(c.read(reviewProvider).questions.single.status, ContentStatus.inReview);
  });

  test('rubric needs a name and criteria', () async {
    final c = testContainer();
    await expectLater(
      c.read(reviewProvider.notifier).saveRubric(const Rubric(id: 'x', name: '', use: RubricUse.essay, criteria: [], status: ContentStatus.draft, owner: 'me')),
      throwsA(isA<ApiException>()),
    );
  });

  test('official marks are final; grading assignment work is stored', () async {
    final c = testContainer();
    final t = c.read(teacherProvider.notifier);
    final sub = c.read(teacherProvider).pending.first;
    await t.review(sub.id, 7, 'ok', official: true);
    expect(c.read(teacherProvider).submissions.firstWhere((s) => s.id == sub.id).stage, EvalStage.official);
    await expectLater(t.review(sub.id, 8, 'again'), throwsA(isA<ApiException>()));
    final a = c.read(teacherProvider).assignments.first;
    final w = a.work().firstWhere((x) => x.status != WorkStatus.missing);
    await t.gradeWork(a.id, w.student, 9, 'ভালো');
    expect(c.read(teacherProvider).assignments.first.grades[w.student], 9);
  });

  testWidgets('teacher writes a question and submits it for review', (tester) async {
    await tester.pumpWidget(testApp(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuestionEditorScreen())), child: const Text('open')),
        ),
      ),
      lang: AppLanguage.en,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tq.stem')), 'What is speed?');
    await tester.enterText(find.byKey(const Key('tq.options')), 'Distance per time\nForce per area');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('tq.submit')));
    await tester.tap(find.byKey(const Key('tq.submit')));
    await tester.pumpAndSettle();
    expect(find.text('Submitted for review'), findsOneWidget);
  });

  testWidgets('review item locks steps the role may not take', (tester) async {
    await tester.pumpWidget(testApp(const ReviewItemScreen(id: 'rv-1'), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    final start = find.byKey(const Key('review.to.inReview'));
    await tester.ensureVisible(start);
    expect(tester.widget<ButtonStyleButton>(start).onPressed, isNull);
    final reviewer = find.descendant(of: find.byKey(const Key('review.acting')), matching: find.text('Content reviewer'));
    await tester.ensureVisible(reviewer);
    await tester.tap(reviewer);
    await tester.pumpAndSettle();
    expect(tester.widget<ButtonStyleButton>(start).onPressed, isNotNull);
  });

  testWidgets('evaluation lists all four stages', (tester) async {
    await tester.pumpWidget(testApp(const TeacherEvaluationScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.textContaining('AI estimate ('), findsOneWidget);
    expect(find.textContaining('Teacher review requested ('), findsOneWidget);
  });
}
