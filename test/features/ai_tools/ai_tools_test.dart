import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/ai_tools/ai_tools_screens.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_voice.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_repository.dart';

import '../../helpers/test_app.dart';

void main() {
  test('handwriting estimate is deterministic and within the total', () {
    final q = testContainer().read(questionRepositoryProvider).cached.first;
    final a = evaluateHandwriting(q, 2);
    expect(evaluateHandwriting(q, 2).marks, a.marks);
    expect(a.marks, inInclusiveRange(0, a.total));
    expect(a.criteria, hasLength(3));
  });

  testWidgets('photo solver: sample image → extracted text → step-by-step solution', (tester) async {
    await tester.pumpWidget(testApp(const PhotoSolverScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.demo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photo.text')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('photo.solve')));
    await tester.tap(find.byKey(const Key('photo.solve')));
    await tester.pumpAndSettle();
    expect(find.text('Solution'), findsOneWidget);
  });

  testWidgets('handwriting: needs a page, then shows an estimate', (tester) async {
    await tester.pumpWidget(testApp(const HandwritingScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hw.demo')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('hw.evaluate')));
    await tester.tap(find.byKey(const Key('hw.evaluate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hw.marks')), findsOneWidget);
    expect(find.textContaining('not final'), findsOneWidget);
  });

  testWidgets('voice tutor: without a microphone offers sample questions and answers them', (tester) async {
    await tester.pumpWidget(testApp(const VoiceTutorScreen(), lang: AppLanguage.en, overrides: [avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voice.session')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('What is acceleration?'));
    await tester.pumpAndSettle();
    expect(find.text('Transcript'), findsOneWidget);
    await tester.tap(find.byKey(const Key('voice.session')));
    await tester.pumpAndSettle();
  });
}
