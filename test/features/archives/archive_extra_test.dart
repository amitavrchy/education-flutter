import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/archives/archive_data.dart';
import 'package:shikkhaai_mobile/features/archives/archive_screens.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_repository.dart';

import '../../helpers/test_app.dart';

void main() {
  test('saving and reporting a paper persists', () async {
    final c = testContainer();
    final a = c.read(archiveProvider.notifier);
    expect(await a.toggleSaved('bp-dhaka-2024-ssc-phy'), isTrue);
    await a.report('bp-dhaka-2024-ssc-phy', 'ভুল উত্তর');
    expect(c.read(archiveProvider).saved, ['bp-dhaka-2024-ssc-phy']);
    expect(c.read(archiveProvider).reported.keys, contains('bp-dhaka-2024-ssc-phy'));
    expect(await a.toggleSaved('bp-dhaka-2024-ssc-phy'), isFalse);
  });

  test('some institution papers are private or teacher uploaded', () {
    final c = testContainer();
    final papers = institutionPapers(c.read(questionRepositoryProvider).cached);
    expect(papers.any(paperIsPrivate), isTrue);
    expect(papers.any(paperTeacherUploaded), isTrue);
  });

  testWidgets('solved view shows answers and the MCQ answer sheet', (tester) async {
    await tester.pumpWidget(testApp(const ArchivePaperScreen(paperId: 'bp-dhaka-2024-ssc-phy'), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('paper.solved')));
    await tester.tap(find.byKey(const Key('paper.solved')));
    await tester.pumpAndSettle();
    expect(find.text('MCQ answer sheet'), findsOneWidget);
    expect(find.text('Source & permission'), findsOneWidget);
  });

  testWidgets('HSC 2020 explains why there are no papers', (tester) async {
    await tester.pumpWidget(testApp(const BoardArchiveScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HSC'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('board.year')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2020').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('No HSC exam was held in 2020'), findsOneWidget);
  });
}
