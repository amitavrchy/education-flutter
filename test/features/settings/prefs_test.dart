import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/network/api_exception.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/application/tutor_controller.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/domain/tutor_models.dart';
import 'package:shikkhaai_mobile/features/settings/learning_prefs.dart';

import '../../helpers/test_app.dart';

void main() {
  test('tutor preferences become the default conversation context', () async {
    final c = testContainer();
    await c.read(learningPrefsProvider.notifier).update((p) => p.copyWith(tutorMode: TeachingMode.socratic, tutorLanguage: TutorLanguage.mixed));
    final ctx = c.read(tutorProvider.notifier).defaultContext();
    expect(ctx.mode, TeachingMode.socratic);
    expect(ctx.language, TutorLanguage.mixed);
  });

  test('password change validates length; sign out of other devices keeps this one', () async {
    final c = testContainer();
    final p = c.read(learningPrefsProvider.notifier);
    await expectLater(p.changePassword('old', 'short'), throwsA(isA<ApiException>()));
    await p.changePassword('old', 'long-enough-1');
    expect(c.read(learningPrefsProvider).passwordChangedAt, isNotNull);
    expect(c.read(learningPrefsProvider).sessions.length, greaterThan(1));
    await p.signOutOthers();
    expect(c.read(learningPrefsProvider).sessions.single.current, isTrue);
  });

  testWidgets('security screen toggles two-step verification', (tester) async {
    await tester.pumpWidget(testApp(const SecurityScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('sec.twoStep')));
    await tester.tap(find.byKey(const Key('sec.twoStep')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('sec.twoStep'))).value, isTrue);
  });

  testWidgets('preferences screen renders every section', (tester) async {
    await tester.pumpWidget(testApp(const PreferencesScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('Learning preferences'), findsOneWidget);
    expect(find.text('AI tutor'), findsOneWidget);
    expect(find.text('Voice'), findsWidgets);
  });
}
