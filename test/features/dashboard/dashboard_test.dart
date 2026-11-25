import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/settings/app_settings.dart';
import 'package:shikkhaai_mobile/features/dashboard/presentation/student_home_screen.dart';
import 'package:shikkhaai_mobile/features/dashboard/presentation/widgets/greeting_header.dart';

import '../../helpers/test_app.dart';

void main() {
  test('saved order keeps known widgets and appends new ones', () {
    final order = DashWidget.ordered(['quick', 'nope', 'goal']);
    expect(order.first, DashWidget.quick);
    expect(order[1], DashWidget.goal);
    expect(order.length, DashWidget.values.length);
  });

  test('greeting follows the time of day', () {
    expect(GreetingHeader.greetingFor(DateTime(2026, 1, 1, 8)).en, 'Good morning');
    expect(GreetingHeader.greetingFor(DateTime(2026, 1, 1, 19)).en, 'Good evening');
  });

  testWidgets('renders every widget by default', (tester) async {
    await tester.pumpWidget(testApp(const StudentHomeScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    for (final w in [DashWidget.summary, DashWidget.goal, DashWidget.dailyQuiz, DashWidget.calendar, DashWidget.subscription, DashWidget.quick]) {
      expect(find.byKey(Key('dash.${w.name}')), findsOneWidget, reason: w.name);
    }
  });

  testWidgets('hiding a widget in the customise sheet removes it and persists', (tester) async {
    late AppSettings Function() settings;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      settings = () => ref.read(appSettingsProvider);
      return const StudentHomeScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dash.customise')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dash.toggle.summary')));
    await tester.pumpAndSettle();
    expect(settings().hiddenWidgets, contains('summary'));
    await tester.tap(find.byKey(const Key('dash.reset')));
    await tester.pumpAndSettle();
    expect(settings().hiddenWidgets, isNot(contains('summary')));
  });

  testWidgets('intro card is dismissed once', (tester) async {
    await tester.pumpWidget(testApp(const StudentHomeScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dash.introOk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dash.introOk')), findsNothing);
  });
}
