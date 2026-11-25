import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Tab;
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/dashboard/presentation/student_home_screen.dart';
import 'package:shikkhaai_mobile/features/insights/insights_engine.dart';
import 'package:shikkhaai_mobile/features/insights/insights_screens.dart';
import 'package:shikkhaai_mobile/features/notifications/application/notifications_controller.dart';
import 'package:shikkhaai_mobile/features/progress/application/learning_progress_controller.dart';
import 'package:shikkhaai_mobile/features/progress/domain/learning_progress.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('analytics shows mastery and weak chapters from seeded progress', (tester) async {
    await tester.pumpWidget(testApp(const AnalyticsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('Subject mastery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('achievements shows level, badges and missions; leaderboard is labelled demo', (tester) async {
    await tester.pumpWidget(testApp(const AchievementsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.textContaining('Level'), findsWidgets);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Leaderboard (demo)'), findsOneWidget);
    expect(find.text("This week's missions"), findsOneWidget);
  });

  testWidgets('student home renders live sections', (tester) async {
    await tester.pumpWidget(testApp(const StudentHomeScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text("Today's summary"), findsOneWidget);
    expect(find.text('Weekly study time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('celebrating a new badge raises one reward notification and is remembered', () async {
    final c = testContainer();
    await c.read(learningProgressProvider.notifier).logActivity(ActivityKind.lesson, minutes: 10);
    final unseen = c.read(gamificationProvider).unseen;
    expect(unseen.map((b) => b.id), contains('first-step'));
    await c.read(gamificationStoreProvider.notifier).celebrate(unseen);
    expect(c.read(gamificationProvider).unseen, isEmpty);
    expect(c.read(notificationsProvider).where((n) => n.id == 'badge-first-step').length, 1);
  });

  test('friend challenge counts my minutes since it started', () async {
    final c = testContainer();
    await c.read(gamificationStoreProvider.notifier).startChallenge('তানিয়া (ডেমো)', 'minutes', 60, 7);
    await c.read(learningProgressProvider.notifier).logActivity(ActivityKind.practice, minutes: 25);
    final g = c.read(gamificationProvider);
    expect(g.friendChallenges.single.target, 60);
    expect(g.myMinutesSince(g.friendChallenges.single.startedAt), greaterThanOrEqualTo(25));
  });

  test('analytics finds weak topics and a 28-day consistency series', () async {
    final c = testContainer();
    final a = c.read(analyticsProvider);
    expect(a.minutes28.length, 28);
    expect(a.weeklyAccuracy.length, 4);
    expect(a.cells, isNotEmpty);
  });

  testWidgets('analytics has overview, topics and roadmap tabs', (tester) async {
    await tester.pumpWidget(testApp(const AnalyticsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Topics'));
    await tester.pumpAndSettle();
    expect(find.text('Topic heatmap'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Roadmap'));
    await tester.pumpAndSettle();
    expect(find.text('Recommended lesson order'), findsOneWidget);
  });
}
