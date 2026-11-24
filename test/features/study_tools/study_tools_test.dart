import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/settings/app_settings.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_voice.dart';
import 'package:shikkhaai_mobile/features/study_tools/audio_and_offline.dart';
import 'package:shikkhaai_mobile/features/study_tools/english_and_labs.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('english coach: grammar quiz scores answers', (tester) async {
    await tester.pumpWidget(testApp(const EnglishCoachScreen(), lang: AppLanguage.en, overrides: [avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grammar quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('eng.opt.1')));
    await tester.pumpAndSettle();
    expect(find.text('Score: 1/5'), findsOneWidget);
  });

  testWidgets('english coach: writing check corrects a sentence', (tester) async {
    await tester.pumpWidget(testApp(const EnglishCoachScreen(), lang: AppLanguage.en, overrides: [avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())]));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('eng.write')), 'He go to school every day.');
    await tester.tap(find.byKey(const Key('eng.check')));
    await tester.pumpAndSettle();
    expect(find.textContaining('goes', findRichText: true), findsWidgets);
  });

  testWidgets('labs compute motion, current and quadratic roots', (tester) async {
    await tester.pumpWidget(testApp(const LabsScreen(), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    expect(find.text('v = 8.0 m/s · s = 20.0 m'), findsOneWidget);
    expect(find.textContaining('I = V / R = 2.00 A'), findsOneWidget);
    expect(find.textContaining('x = 2.00, -2.00'), findsOneWidget);
  });

  testWidgets('offline: sync fails offline and succeeds online', (tester) async {
    late WidgetRef r;
    await tester.pumpWidget(testApp(Consumer(builder: (context, ref, _) {
      r = ref;
      return const OfflineScreen();
    }), lang: AppLanguage.en));
    await tester.pumpAndSettle();
    await r.read(appSettingsProvider.notifier).update((AppSettings s) => s.copyWith(simulateOffline: true));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('offline.sync')));
    await tester.tap(find.byKey(const Key('offline.sync')));
    await tester.pumpAndSettle();
    expect(find.textContaining('never'), findsOneWidget);
    await r.read(appSettingsProvider.notifier).update((AppSettings s) => s.copyWith(simulateOffline: false));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('offline.sync')));
    await tester.tap(find.byKey(const Key('offline.sync')));
    await tester.pumpAndSettle();
    expect(find.textContaining('never'), findsNothing);
  });

  testWidgets('audio revision lists lessons and toggles favourites', (tester) async {
    await tester.pumpWidget(testApp(const AudioRevisionScreen(), lang: AppLanguage.en, overrides: [avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())]));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audio.k-newton2')), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const Key('audio.k-newton2')), matching: find.byIcon(Icons.favorite_border)));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('audio.k-newton2')), matching: find.byIcon(Icons.favorite)), findsOneWidget);
  });
}
