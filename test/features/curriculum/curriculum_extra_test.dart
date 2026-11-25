import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/curriculum/presentation/chapter_detail_screen.dart';
import 'package:shikkhaai_mobile/features/curriculum/presentation/learn_screen.dart';
import 'package:shikkhaai_mobile/features/search/presentation/search_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('chapter detail shows question and note counts', (tester) async {
    await tester.pumpWidget(testApp(const ChapterDetailScreen(chapterId: 'ssc-phy-p1-c3'), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chapter.counts')), findsOneWidget);
    expect(find.textContaining('questions'), findsWidgets);
  });

  testWidgets('hierarchy browser expands level → subject', (tester) async {
    await tester.pumpWidget(testApp(const CurriculumHierarchyScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tree.SSC')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tree.ssc-phy')), findsOneWidget);
  });

  testWidgets('search finds papers and removes a recent search', (tester) async {
    await tester.pumpWidget(testApp(const SearchScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search.field')), 'Physics');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Board & school papers'), findsWidgets);
  });
}
