import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/search/presentation/search_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('search finds chapters, questions and the book teacher, grouped by kind', (tester) async {
    await tester.pumpWidget(testApp(const SearchScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('Popular topics'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'acceleration');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Chapters & topics'), findsWidgets);
    expect(find.textContaining('All ('), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz-nothing');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
  });
}
