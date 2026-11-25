import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/settings/app_settings.dart';
import 'package:shikkhaai_mobile/features/notes/application/notes_controller.dart';
import 'package:shikkhaai_mobile/features/study_tools/audio_and_offline.dart';

import '../../helpers/test_app.dart';

void main() {
  test('generated lessons, downloads and history persist', () async {
    final c = testContainer();
    final a = c.read(audioProvider.notifier);
    final before = c.read(audioLessonsProvider).length;
    await a.generate('ssc-phy-p1-c1-t1');
    expect(c.read(audioLessonsProvider).length, before + 1);
    expect(c.read(audioLessonsProvider).first.generated, isTrue);
    final id = c.read(audioLessonsProvider).last.id;
    await a.toggleDownload(id);
    await a.started(id);
    expect(c.read(audioProvider).downloads, contains(id));
    expect(c.read(audioProvider).history.first.$1, id);
  });

  test('every scenario lesson has chapter markers', () {
    final c = testContainer();
    expect(c.read(audioLessonsProvider).every((l) => l.sections.length >= 3), isTrue);
  });

  testWidgets('offline shows the AI-unavailable state and resolves a sync conflict', (tester) async {
    late ProviderContainer Function() container;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      container = () => ProviderScope.containerOf(context);
      return const OfflineScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await container().read(appSettingsProvider.notifier).update((s) => s.copyWith(simulateOffline: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline.aiUnavailable')), findsOneWidget);
    await container().read(appSettingsProvider.notifier).update((s) => s.copyWith(simulateOffline: false));
    if (container().read(notesProvider).isEmpty) await container().read(notesProvider.notifier).create(title: 'n', body: 'b');
    await tester.pumpAndSettle();
    final notes = container().read(notesProvider).length;
    await tester.ensureVisible(find.byKey(const Key('offline.simConflict')));
    await tester.tap(find.byKey(const Key('offline.simConflict')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offline.conflict')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('conflict.both')));
    await tester.tap(find.byKey(const Key('conflict.both')));
    await tester.pumpAndSettle();
    expect(container().read(notesProvider).length, notes + 1);
    expect(find.byKey(const Key('offline.conflict')), findsNothing);
  });
}
