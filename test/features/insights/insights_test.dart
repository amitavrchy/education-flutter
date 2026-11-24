import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/dashboard/presentation/student_home_screen.dart';
import 'package:shikkhaai_mobile/features/insights/insights_screens.dart';

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
    expect(find.text('This week'), findsOneWidget);
    expect(find.text("Today's plan"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
