import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/application/tutor_controller.dart';
import 'package:shikkhaai_mobile/features/notes/application/notes_controller.dart';
import 'package:shikkhaai_mobile/features/notes/domain/note.dart';
import 'package:shikkhaai_mobile/features/progress/application/learning_progress_controller.dart';
import 'package:shikkhaai_mobile/features/progress/domain/learning_progress.dart';
import 'package:shikkhaai_mobile/mock/seed/questions_seed.dart';

import '../../helpers/test_app.dart';

void main() {
  test('create, autosave, snapshot history and restore', () async {
    final c = testContainer();
    addTearDown(c.dispose);
    final ctl = c.read(notesProvider.notifier);
    final n = await ctl.create(title: 'Draft', body: 'v1');
    expect(c.read(learningProgressProvider).activities.first.kind, ActivityKind.notes);
    await ctl.save(n.id, body: 'v2'); // quick autosave: no snapshot
    expect(ctl.byId(n.id)!.history, isEmpty);
    await ctl.save(n.id, body: 'v3', snapshot: true);
    final saved = ctl.byId(n.id)!;
    expect(saved.body, 'v3');
    expect(saved.history.first.body, 'v2');
    await ctl.restore(n.id, saved.history.first);
    expect(ctl.byId(n.id)!.body, 'v2');
    expect(ctl.byId(n.id)!.history.first.body, 'v3');
  });

  test('folders, tags, favourites, two-way links and delete cleanup', () async {
    final c = testContainer();
    addTearDown(c.dispose);
    final ctl = c.read(notesProvider.notifier);
    final a = await ctl.create(title: 'A');
    final b = await ctl.create(title: 'B');
    await ctl.setFolder(a.id, 'Physics');
    await ctl.setTags(a.id, [' Exam', 'formula', 'exam']);
    await ctl.toggleFavorite(a.id);
    await ctl.link(a.id, b.id);
    expect(ctl.byId(a.id)!.tags, ['exam', 'formula']);
    expect(ctl.byId(b.id)!.linkedIds, [a.id]);
    await ctl.delete(a.id);
    expect(ctl.byId(b.id)!.linkedIds, isEmpty);
  });

  test('generators: chapter formula sheet, question, conversation and upload are labelled AI', () async {
    final c = testContainer();
    addTearDown(c.dispose);
    final ctl = c.read(notesProvider.notifier);
    final sheet = await ctl.generateFromChapter('ssc-phy-p1-c3', NoteType.formulaSheet, AppLanguage.en);
    expect(sheet.body, contains('F = ma'));
    expect(sheet.aiGenerated, isTrue);
    final q = await ctl.generateFromQuestion(seedQuestions().firstWhere((q) => q.id == 'q-phy-m4'), AppLanguage.en);
    expect(q.body, contains('25 m'));
    final conv = c.read(tutorProvider.notifier).byId('c-seed-1')!;
    final fromChat = await ctl.generateFromConversation(conv, AppLanguage.bn);
    expect(fromChat.source, NoteSource.conversation);
    expect(fromChat.body, contains('নিউটন'));
    final up = await ctl.generateFromUpload('scan.pdf', 2048, AppLanguage.en);
    expect(up.body, contains('simulated'));
  });

  test('every note type generates non-empty content', () {
    final c = testContainer();
    addTearDown(c.dispose);
    final gen = c.read(notesProvider.notifier).generator;
    final repo = gen.curriculum;
    final ch = repo.findChapter('ssc-chem-p1-c5')!;
    for (final type in NoteType.values) {
      final r = gen.fromTopics(scopeTitle: 'Bonds', topics: [for (final t in ch.chapter.topics) repo.findTopic(t.id)!], type: type, lang: AppLanguage.bn);
      expect(r.body.split('\n').length, greaterThan(2), reason: type.name);
    }
  });
}
