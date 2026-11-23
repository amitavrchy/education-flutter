import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/settings/app_settings.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/application/tutor_controller.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/data/mock_tutor_engine.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/domain/tutor_models.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/presentation/tutor_chat_screen.dart';
import 'package:shikkhaai_mobile/features/curriculum/data/curriculum_repository.dart';
import 'package:shikkhaai_mobile/core/mock/mock_simulator.dart';
import 'package:shikkhaai_mobile/mock/seed/questions_seed.dart';

import '../../helpers/test_app.dart';

void main() {
  final engine = MockTutorEngine(
    curriculum: MockCurriculumRepository(MockSimulator(latency: Duration.zero, settings: () => const AppSettings())),
    questions: seedQuestions,
  );

  group('mock RAG engine', () {
    test('retrieves the right passage in Bangla and English', () {
      expect(engine.retrieve('নিউটনের দ্বিতীয় সূত্র কী?', const TutorContext()).first.$1.id, 'k-newton2');
      expect(engine.retrieve('what is photosynthesis', const TutorContext()).first.$1.id, 'k-photosynthesis');
    });

    test('context changes retrieval: a generic question follows the selected topic', () {
      final hits = engine.retrieve('explain this', const TutorContext(subjectId: 'ssc-chem', chapterId: 'ssc-chem-p1-c6', topicId: 'ssc-chem-p1-c6-t1'));
      expect(hits.first.$1.id, 'k-mole');
    });

    test('verified answers cite a sample textbook with page and related questions', () {
      final r = engine.answer(query: 'F = ma newton second law', context: const TutorContext(subjectId: 'ssc-phy', topicId: 'ssc-phy-p1-c3-t1'));
      expect(r.grounding, Grounding.verified);
      expect(r.sources.first.page, 46);
      expect(r.sources.first.bookTitle.en, contains('sample textbook'));
      expect(r.relatedQuestionIds, isNotEmpty);
      expect(r.followUps, isNotEmpty);
    });

    test('each teaching mode produces a distinct answer', () {
      final texts = {
        for (final m in TeachingMode.values.where((m) => m != TeachingMode.englishCoach))
          engine.answer(query: 'newton second law', context: TutorContext(mode: m)).text,
      };
      expect(texts.length, TeachingMode.values.length - 1);
    });

    test('regenerating gives a different version', () {
      final a = engine.answer(query: 'acceleration', context: const TutorContext(), variant: 0).text;
      final b = engine.answer(query: 'acceleration', context: const TutorContext(), variant: 1).text;
      expect(a, isNot(b));
    });

    test('old-curriculum sources are flagged', () {
      final r = engine.answer(query: 'equation of motion v = u + at', context: const TutorContext());
      expect(r.warnings, contains(AnswerWarning.oldCurriculum));
      expect(r.grounding, isNot(Grounding.verified));
    });

    test('unknown topics fall back to a low-confidence general explanation', () {
      final r = engine.answer(query: 'Explain the civics of local government', context: const TutorContext(subjectId: 'hsc-civics'));
      expect(r.grounding, Grounding.unavailable);
      expect(r.warnings, containsAll([AnswerWarning.lowConfidence, AnswerWarning.missingKnowledge]));
      expect(r.sources, isEmpty);
    });

    test('integrity and off-topic safety responses', () {
      expect(engine.answer(query: 'give me the leaked question paper', context: const TutorContext()).warnings, [AnswerWarning.integrity]);
      expect(engine.answer(query: 'suggest a movie', context: const TutorContext()).warnings, [AnswerWarning.offTopic]);
    });

    test('English coach corrects subject-verb agreement', () {
      final r = engine.answer(query: 'each of the boys have a book', context: const TutorContext(mode: TeachingMode.englishCoach, language: TutorLanguage.en));
      expect(r.text, contains('Each of the boys has a book.'));
    });

    test('oral exam grades the reply to the previous question', () {
      const ctx = TutorContext(mode: TeachingMode.oralExam, language: TutorLanguage.en);
      final q = engine.answer(query: 'newton second law', context: ctx);
      final history = [
        ChatMessage(id: 'a', role: ChatRole.assistant, text: q.text, createdAt: DateTime(2026), mode: TeachingMode.oralExam, sources: q.sources),
      ];
      final graded = engine.answer(query: 'F = ma so 12 N', context: ctx, history: history);
      expect(graded.text, contains('Model answer'));
    });
  });

  group('tutor controller', () {
    test('seeds sample conversations', () {
      final c = testContainer();
      addTearDown(c.dispose);
      expect(c.read(tutorProvider), hasLength(3));
    });

    test('send streams an answer and saves it with metadata', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(tutorProvider.notifier);
      final conv = await ctl.create(context: const TutorContext(subjectId: 'ssc-phy'));
      await ctl.send(conv.id, 'What is acceleration?');
      final saved = ctl.byId(conv.id)!;
      expect(saved.title, 'What is acceleration?');
      expect(saved.messages, hasLength(2));
      final answer = saved.messages.last;
      expect(answer.status, MessageStatus.done);
      expect(answer.sources, isNotEmpty);
      expect(answer.text, isNotEmpty);
    });

    test('regenerate keeps the correction history; editing re-asks and trims', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(tutorProvider.notifier);
      final conv = await ctl.create();
      await ctl.send(conv.id, 'photosynthesis');
      final firstAnswer = ctl.byId(conv.id)!.messages.last;
      await ctl.regenerate(conv.id, firstAnswer.id);
      final regenerated = ctl.byId(conv.id)!.messages.last;
      expect(regenerated.versions, [firstAnswer.text]);

      final userMsg = ctl.byId(conv.id)!.messages.first;
      await ctl.editUserMessage(conv.id, userMsg.id, 'mole concept');
      final edited = ctl.byId(conv.id)!;
      expect(edited.messages, hasLength(2));
      expect(edited.messages.first.text, 'mole concept');
      expect(edited.messages.first.editedAt, isNotNull);
      expect(edited.messages.last.sources.first.id, 'k-mole');
    });

    test('offline answers fail with a retryable error', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      await c.read(appSettingsProvider.notifier).update((s) => s.copyWith(simulateOffline: true));
      final ctl = c.read(tutorProvider.notifier);
      final conv = await ctl.create();
      await ctl.send(conv.id, 'ohm law');
      final failed = ctl.byId(conv.id)!.messages.last;
      expect(failed.status, MessageStatus.error);
      expect(failed.error, 'OFFLINE');

      await c.read(appSettingsProvider.notifier).update((s) => s.copyWith(simulateOffline: false));
      await ctl.retry(conv.id, failed.id);
      expect(ctl.byId(conv.id)!.messages.last.status, MessageStatus.done);
    });

    test('pin, archive, folder, feedback, bookmark and teacher review persist', () async {
      final c = testContainer();
      addTearDown(c.dispose);
      final ctl = c.read(tutorProvider.notifier);
      final conv = ctl.byId('c-seed-2')!;
      final answer = conv.messages.last;
      await ctl.togglePin(conv.id);
      await ctl.toggleArchive(conv.id);
      await ctl.setFolder(conv.id, 'Biology');
      await ctl.setFeedback(conv.id, answer.id, 1);
      await ctl.toggleBookmark(conv.id, answer.id);
      await ctl.requestTeacherReview(conv.id, answer.id);
      c.invalidate(tutorProvider);
      final after = c.read(tutorProvider.notifier).byId(conv.id)!;
      expect(after.pinned && after.archived, isTrue);
      expect(after.folder, 'Biology');
      expect(after.messages.last.feedback, 1);
      expect(after.messages.last.teacherReview, isTrue);
      expect(c.read(tutorProvider.notifier).bookmarkedAnswers, hasLength(1));
    });
  });

  testWidgets('student asks the tutor and sees a source citation', (tester) async {
    late ProviderContainer container;
    await tester.pumpWidget(testApp(
      Consumer(builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        return const TutorChatScreen(conversationId: 'c-seed-1');
      }),
      lang: AppLanguage.en,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('source.k-newton2')), findsWidgets);

    await tester.enterText(find.byKey(const Key('chat.input')), 'What is a mole?');
    await tester.tap(find.byKey(const Key('chat.send')));
    await tester.pumpAndSettle();
    expect(container.read(tutorProvider.notifier).byId('c-seed-1')!.messages.length, 4);
    expect(find.byKey(const Key('source.k-mole')), findsOneWidget);

    await tester.tap(find.byKey(const Key('source.k-mole')));
    await tester.pumpAndSettle();
    expect(find.text('Source viewer'), findsOneWidget);
    expect(find.textContaining('Sample textbook'), findsOneWidget);
  });
}
