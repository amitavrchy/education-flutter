import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/network/api_exception.dart';
import 'package:shikkhaai_mobile/core/settings/app_settings.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_controller.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_voice.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/book_avatar_engine.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/book_catalog.dart';
import 'package:shikkhaai_mobile/features/book_avatar/domain/avatar_models.dart';
import 'package:shikkhaai_mobile/features/book_avatar/presentation/avatar_classroom_screen.dart';
import 'package:shikkhaai_mobile/features/book_avatar/presentation/avatar_role_screens.dart';
import 'package:shikkhaai_mobile/features/book_avatar/presentation/teacher_avatar.dart';

import '../../helpers/test_app.dart';

final _noAuth = [avatarUserIdProvider.overrideWithValue(demoStudentId), avatarReviewerNameProvider.overrideWithValue('শিক্ষক')];

void main() {
  const engine = BookAvatarEngine();
  final physics = bookById('book-ssc-phy')!;
  final avatar = defaultAvatarFor(physics);

  group('book avatar engine (answers only from its book)', () {
    test('answers an in-book question with a page citation from that book', () {
      final a = engine.answer(book: physics, avatar: avatar, query: 'ত্বরণ কাকে বলে?');
      expect(a.grounded, Grounding.book);
      expect(a.citations, isNotEmpty);
      expect(a.citations.first.page, 22);
      expect(a.followUps, isNotEmpty);
    });

    test('finds topics on the book pages when no detailed passage matches', () {
      final a = engine.answer(book: physics, avatar: avatar, query: 'পরিমাপের ত্রুটি');
      expect(a.grounded, Grounding.book);
      expect(a.citations.single.heading, contains('ত্রুটি'));
    });

    test('declines out-of-book questions and suggests book topics', () {
      final a = engine.answer(book: physics, avatar: avatar, query: 'বাংলাদেশের রাজধানীর নাম কী?');
      expect(a.grounded, Grounding.outOfScope);
      expect(a.citations, isEmpty);
      expect(a.followUps, isNotEmpty);
    });

    test('respects the chapter scope', () {
      final scoped = BookAvatar.fromJson({...avatar.toJson(), 'scopeChapterIds': [physics.chapters.first.id]});
      expect(engine.answer(book: physics, avatar: scoped, query: 'ত্বরণ কাকে বলে?').grounded, Grounding.outOfScope);
    });

    test('replies in the language of the question; greets and lists chapters', () {
      expect(BookAvatarEngine.isBangla(engine.answer(book: physics, avatar: avatar, query: 'What is acceleration?').text), isFalse);
      expect(engine.answer(book: physics, avatar: avatar, query: 'তুমি কে?').grounded, Grounding.greeting);
      final toc = engine.answer(book: physics, avatar: avatar, query: 'এই বইয়ে কী কী অধ্যায় আছে?');
      expect(toc.text, contains(physics.chapters.first.title.bn));
    });

    test('speakable text has no markdown, links or LaTeX markup', () {
      final spoken = BookAvatarEngine.toSpoken(r'**বল**: $F = ma$ — [পৃষ্ঠা ১২](/x)', 'bn');
      expect(spoken, isNot(matches(RegExp(r'[*$\[\]()]'))));
    });
  });

  test('default avatars are deterministic and varied', () {
    expect(defaultAppearance('x').toJson(), defaultAppearance('x').toJson());
    final all = [for (final b in sampleBooks) defaultAvatarFor(b)];
    expect({for (final a in all) a.name.bn}.length, greaterThan(3));
    expect({for (final a in all) a.appearance.gender}.length, 2);
    expect(all.every((a) => a.status == AvatarStatus.active), isTrue);
  });

  group('avatar controller', () {
    test('runs a class: greeting, grounded answer, stats and session counters', () async {
      final c = testContainer(overrides: _noAuth);
      final ctrl = c.read(avatarControllerProvider.notifier);
      final before = c.read(avatarControllerProvider).avatarForBook(physics.id)!.stats;
      final session = await ctrl.startSession(physics.id);
      expect(c.read(avatarControllerProvider).messagesOf(session.id).single.grounded, Grounding.greeting);
      final reply = await ctrl.ask(session.id, 'নিউটনের দ্বিতীয় সূত্র বুঝিয়ে দাও', voice: true);
      expect(reply.grounded, Grounding.book);
      expect(reply.citations, isNotEmpty);
      final s = c.read(avatarControllerProvider);
      expect(s.messagesOf(session.id), hasLength(3));
      expect(s.session(session.id)!.voiceTurns, 1);
      expect(s.avatarForBook(physics.id)!.stats.questions, before.questions + 1);
      expect(s.avatarForBook(physics.id)!.stats.sessions, before.sessions + 1);

      await ctrl.feedback(reply.id, 'up');
      expect(c.read(avatarControllerProvider).avatarForBook(physics.id)!.stats.helpful, before.helpful + 1);
    });

    test('reports go to teachers and can be resolved', () async {
      final c = testContainer(overrides: _noAuth);
      final ctrl = c.read(avatarControllerProvider.notifier);
      final session = await ctrl.startSession(physics.id);
      final reply = await ctrl.ask(session.id, 'ত্বরণ কাকে বলে?');
      await ctrl.report(reply.id, 'উদাহরণ ভুল');
      final r = c.read(avatarControllerProvider).reports.firstWhere((x) => x.reason == 'উদাহরণ ভুল');
      expect(r.question, 'ত্বরণ কাকে বলে?');
      await ctrl.resolveReport(r.id, ReportStatus.resolved, 'ঠিক করা হয়েছে', 'শিক্ষক');
      expect(c.read(avatarControllerProvider).reports.firstWhere((x) => x.id == r.id).status, ReportStatus.resolved);
    });

    test('needs the network; guardians see counts only', () async {
      final c = testContainer(overrides: _noAuth);
      final ctrl = c.read(avatarControllerProvider.notifier);
      final session = await ctrl.startSession(physics.id);
      await c.read(appSettingsProvider.notifier).update((s) => s.copyWith(simulateOffline: true));
      await expectLater(ctrl.ask(session.id, 'ত্বরণ'), throwsA(isA<ApiException>()));
      final usage = ctrl.usageFor(demoStudentId);
      expect(usage.sessions, greaterThanOrEqualTo(3));
      expect(usage.byBook, isNotEmpty);
    });
  });

  testWidgets('student starts a class, asks by text and sees the book page citation', (tester) async {
    await tester.pumpWidget(testApp(
      const AvatarClassroomScreen(bookId: 'book-ssc-phy'),
      overrides: [..._noAuth, avatarVoiceProvider.overrideWithValue(SilentAvatarVoice())],
    ));
    await tester.pump();
    expect(find.byType(TeacherAvatar), findsOneWidget);

    await tester.tap(find.byKey(const Key('avatar.start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byKey(const Key('avatar.input')), 'ত্বরণ কাকে বলে?');
    await tester.tap(find.byKey(const Key('avatar.send')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const Key('avatar.citation.22')), findsOneWidget);
    expect(find.text('বই থেকে'), findsOneWidget);

    await tester.tap(find.byKey(const Key('avatar.citation.22')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('নমুনা পাঠ্যবই'), findsWidgets);
  });

  testWidgets('teacher resolves a reported answer', (tester) async {
    await tester.pumpWidget(testApp(const Scaffold(body: AvatarReportsList()), overrides: _noAuth));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('avatar.resolution.ar-1')), 'একক m/s² যোগ করা হলো');
    await tester.tap(find.byKey(const Key('avatar.resolve.ar-1')));
    await tester.pump();
    expect(find.textContaining('একক m/s² যোগ করা হলো'), findsOneWidget);
  });
}
