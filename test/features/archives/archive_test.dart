import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/archives/archive_data.dart';
import 'package:shikkhaai_mobile/features/archives/archive_screens.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_repository.dart';
import 'package:shikkhaai_mobile/mock/seed/curriculum_seed.dart';

import '../../helpers/test_app.dart';

void main() {
  test('board papers are deterministic, subject-scoped and skip HSC 2020', () {
    final bank = testContainer().read(questionRepositoryProvider).cached;
    final phy = subjectById('ssc-phy')!;
    final a = boardPaper(bank, subject: phy, boardId: 'dhaka', year: 2023)!;
    final b = boardPaper(bank, subject: phy, boardId: 'dhaka', year: 2023)!;
    expect(a.questionIds, b.questionIds);
    expect(a.questionIds, isNotEmpty);
    expect(a.questionIds.every((id) => bank.firstWhere((q) => q.id == id).subjectId == 'ssc-phy'), isTrue);
    expect(boardPaper(bank, subject: subjectById('hsc-phy')!, boardId: 'dhaka', year: 2020), isNull);
    expect(paperById(bank, a.id)!.questionIds, a.questionIds);
  });

  test('institution papers belong to demo institutions with categories', () {
    final bank = testContainer().read(questionRepositoryProvider).cached;
    final papers = institutionPapers(bank);
    expect(papers, isNotEmpty);
    expect(papers.every((p) => p.institution != null && p.category != null), isTrue);
    expect(paperById(bank, papers.first.id)!.title.en, papers.first.title.en);
  });

  testWidgets('board archive lists papers and opens one with its questions', (tester) async {
    await tester.pumpWidget(testApp(const BoardArchiveScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('paper.bp-dhaka-2024-ssc-phy')), findsOneWidget);

    await tester.pumpWidget(testApp(const ArchivePaperScreen(paperId: 'bp-dhaka-2024-ssc-phy'), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('Board-style sample (synthetic)'), findsOneWidget);
    expect(find.byKey(const Key('paper.practise')), findsOneWidget);
  });
}
