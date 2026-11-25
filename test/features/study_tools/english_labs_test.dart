import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_voice.dart';
import 'package:shikkhaai_mobile/features/study_tools/english_coach.dart';
import 'package:shikkhaai_mobile/features/study_tools/labs.dart';

import '../../helpers/test_app.dart';

void main() {
  test('pronunciation score counts recognised words', () {
    final (score, missed) = pronunciationScore('The weather is pleasant today.', 'the weather is nice today');
    expect(score, 80);
    expect(missed, ['pleasant']);
  });

  test('english progress averages recent scores and plans weakest skills first', () async {
    final c = testContainer();
    final e = c.read(englishProvider.notifier);
    await e.record(EngSkill.grammar, 90);
    await e.record(EngSkill.reading, 40);
    final p = c.read(englishProvider);
    expect(p.average(EngSkill.grammar), 90);
    expect(p.plan.first, isNot(EngSkill.grammar));
  });

  test('calculator evaluates precedence, powers and functions', () {
    expect(evaluateExpression('2+3×4'), 14);
    expect(evaluateExpression('2^3+1'), 9);
    expect(evaluateExpression('sin(30)'), closeTo(0.5, 1e-9));
    expect(evaluateExpression('√(16)'), 4);
    expect(() => evaluateExpression('2+'), throwsFormatException);
  });

  test('bond type follows electronegativity difference', () {
    expect(bondType(0.93, 3.16), 'ionic');
    expect(bondType(2.20, 3.44), 'polar');
    expect(bondType(2.55, 2.55), 'covalent');
  });

  testWidgets('every available lab opens; planned labs are marked', (tester) async {
    for (final lab in labCatalog.where((l) => l.available)) {
      await tester.pumpWidget(testApp(LabScreen(lab: lab), lang: AppLanguage.en));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: lab.id);
    }
    await tester.pumpWidget(testApp(const LabsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsWidgets);
    expect(labCatalog.where((l) => l.available).length, greaterThanOrEqualTo(21));
  });

  testWidgets('reaction lab confirms a balanced equation', (tester) async {
    await tester.pumpWidget(testApp(LabScreen(lab: labCatalog.firstWhere((l) => l.id == 'reactions')), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('Not balanced yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rx.plus.0')));
    await tester.tap(find.byKey(const Key('rx.plus.2')));
    await tester.pumpAndSettle();
    expect(find.text('✓ Balanced!'), findsOneWidget);
  });

  testWidgets('english: sentence correction and mock speaking exam', (tester) async {
    await tester.pumpWidget(testApp(const EnglishCoachScreen(), lang: AppLanguage.en, overrides: [avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())]));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sentence correction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sentence correction'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('eng.fix')), 'He goes to school every day.');
    await tester.tap(find.byKey(const Key('eng.fixCheck')));
    await tester.pumpAndSettle();
    expect(find.text('Correct!'), findsOneWidget);
    await tester.ensureVisible(find.text('Mock speaking exam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mock speaking exam'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exam.start')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.enterText(find.byKey(const Key('exam.answer')), 'I really enjoy reading books and playing cricket with my friends after school.');
      await tester.tap(find.byKey(const Key('exam.submit')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('exam.done')), findsOneWidget);
  });

  testWidgets('progress tab reflects recorded practice', (tester) async {
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) => const EnglishCoachScreen()), lang: AppLanguage.en, overrides: [avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())]));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Your improvement plan'), findsOneWidget);
  });
}
