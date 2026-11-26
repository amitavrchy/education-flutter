import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/insights/insights_engine.dart';

void main() {
  test('server gamification maps XP, streak and the badges the app knows', () {
    final g = ServerGamification.fromJson({
      'xp': 4843,
      'points': 1266,
      'streak': {'current': 4, 'longest': 17},
      'badges': [
        {'id': 'first-steps', 'earnedAt': '2026-10-05T03:00:00.000Z'},
        {'id': 'questions-100', 'earnedAt': '2026-10-25T03:00:00.000Z'},
        {'id': 'night-owl', 'earnedAt': '2026-11-04T03:00:00.000Z'},
      ],
    });
    expect(g.xp, 4843);
    expect(g.streak, 4);
    expect(g.badges.keys, ['first-step', 'q-100']);
  });
}
