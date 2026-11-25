import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/ai_tools/ai_tools_data.dart';
import 'package:shikkhaai_mobile/features/ai_tools/ai_tools_screens.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_voice.dart';
import 'package:shikkhaai_mobile/features/notes/application/notes_controller.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_data.dart';

import '../../helpers/test_app.dart';

void main() {
  test('file validation accepts images up to 10 MB', () {
    expect(validImageFile('a.JPG', 1000), isTrue);
    expect(validImageFile('a.pdf', 1000), isFalse);
    expect(validImageFile('a.png', 11 * 1024 * 1024), isFalse);
  });

  test('voice session minutes count toward the monthly allowance', () async {
    final c = testContainer();
    final now = DateTime.now();
    await c.read(aiToolsProvider.notifier).saveSession(VoiceSession(
      id: 'v1',
      startedAt: now.subtract(const Duration(minutes: 4)),
      endedAt: now,
      mode: 'simple',
      language: 'bn',
      turns: const [(true, 'প্রশ্ন'), (false, 'উত্তর')],
    ));
    expect(c.read(aiToolsProvider).minutesThisMonth(now), 4);
  });

  testWidgets('voice: mic denied banner, conversation → notes, session saved to history', (tester) async {
    late ProviderContainer Function() container;
    await tester.pumpWidget(testApp(
      Consumer(builder: (context, ref, _) {
        container = () => ProviderScope.containerOf(context);
        return const VoiceTutorScreen();
      }),
      lang: AppLanguage.en,
      overrides: [avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voice.session')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('voice.micDenied')), findsOneWidget);
    await tester.tap(find.text('What is acceleration?'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('voice.toNotes')));
    await tester.tap(find.byKey(const Key('voice.toNotes')));
    await tester.pumpAndSettle();
    expect(container().read(notesProvider).any((n) => n.body.contains('acceleration')), isTrue);
    await tester.ensureVisible(find.byKey(const Key('voice.session')));
    await tester.tap(find.byKey(const Key('voice.session')));
    await tester.pumpAndSettle();
    expect(container().read(aiToolsProvider).sessions, hasLength(1));
  });

  testWidgets('photo: solve is saved to history and can be added to practice', (tester) async {
    late ProviderContainer Function() container;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      container = () => ProviderScope.containerOf(context);
      return const PhotoSolverScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.demo')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('photo.solve')));
    await tester.tap(find.byKey(const Key('photo.solve')));
    await tester.pumpAndSettle();
    expect(container().read(aiToolsProvider).solves, hasLength(1));
    await tester.ensureVisible(find.byKey(const Key('photo.practice')));
    await tester.tap(find.byKey(const Key('photo.practice')));
    await tester.pumpAndSettle();
    expect(find.text('Added to your practice list (bookmarks)'), findsOneWidget);
  });

  testWidgets('handwriting: teacher review request reaches the teacher queue', (tester) async {
    late ProviderContainer Function() container;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      container = () => ProviderScope.containerOf(context);
      return const HandwritingScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    final before = container().read(teacherProvider).submissions.length;
    await tester.tap(find.byKey(const Key('hw.demo')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('hw.evaluate')));
    await tester.tap(find.byKey(const Key('hw.evaluate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hw.ocr')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('hw.review')));
    await tester.tap(find.byKey(const Key('hw.review')));
    await tester.pumpAndSettle();
    expect(container().read(teacherProvider).submissions.length, before + 1);
    expect(container().read(aiToolsProvider).evaluations.single.submissionId, isNotNull);
  });
}
