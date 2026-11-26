import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/storage/local_store.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/book_catalog.dart';
import 'package:shikkhaai_mobile/features/curriculum/application/catalog_sync.dart';
import 'package:shikkhaai_mobile/features/curriculum/data/curriculum_catalog.dart';
import 'package:shikkhaai_mobile/features/curriculum/domain/curriculum_models.dart';
import 'package:shikkhaai_mobile/features/curriculum/presentation/chapter_detail_screen.dart';
import 'package:shikkhaai_mobile/features/curriculum/presentation/learn_screen.dart';
import 'package:shikkhaai_mobile/features/dashboard/presentation/student_home_screen.dart';
import 'package:shikkhaai_mobile/features/exams/presentation/exam_setup_screen.dart';
import 'package:shikkhaai_mobile/features/insights/insights_screens.dart';
import 'package:shikkhaai_mobile/features/library/library_screens.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_mapper.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_repository.dart';
import 'package:shikkhaai_mobile/features/question_bank/domain/question.dart';
import 'package:shikkhaai_mobile/features/question_bank/presentation/question_bank_screen.dart';
import 'package:shikkhaai_mobile/mock/seed/curriculum_seed.dart';

import '../../helpers/test_app.dart';

final _fixture = jsonDecode(File('test/fixtures/catalog_sample.json').readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _list(String k) => [for (final x in _fixture[k] as List) (x as Map).cast<String, dynamic>()];

/// A store holding the synced fixture, as CatalogSync leaves it.
MemoryLocalStore _syncedStore() {
  final store = MemoryLocalStore();
  store.put(CatalogSync.collection, CatalogSync.curriculumKey, {for (final k in ['subjects', 'papers', 'chapters', 'topics', 'outcomes']) k: _fixture[k]});
  store.putAll('questions', {for (final q in _list('questions')) q['id'] as String: questionFromApi(q).toJson()});
  store.put('_meta', 'seeded:questions', {'at': 'now'});
  return store;
}

void main() {
  tearDown(CurriculumCatalog.reset);

  test('backend curriculum maps to subjects, chapters, topics and outcomes', () {
    final subjects = subjectsFromApi(subjects: _list('subjects'), papers: _list('papers'), chapters: _list('chapters'), topics: _list('topics'), outcomes: _list('outcomes'));
    final phy = subjects.firstWhere((s) => s.id == 'ssc-physics');
    expect(phy.level, EducationLevel.ssc);
    expect(phy.groups, contains(AcademicGroup.science));
    expect(phy.chapters.map((c) => c.number), orderedEquals([...phy.chapters.map((c) => c.number)]..sort()));
    final ch = phy.chapters.first;
    expect(ch.id, startsWith('ssc-physics-c'));
    expect(ch.topics, isNotEmpty);
    expect(ch.topics.expand((t) => t.outcomes), isNotEmpty);
    expect(phy.icon, Icons.bolt);
  });

  test('every question type maps without losing its answer data', () {
    final qs = [for (final q in _list('questions')) questionFromApi(q)];
    final byType = {for (final q in qs) q.type: q};
    expect(byType[QuestionType.mcq]!.correctIndex, isNotNull);
    expect(byType[QuestionType.mcq]!.options.length, greaterThanOrEqualTo(2));
    expect(byType[QuestionType.trueFalse]!.options.length, 2);
    expect(byType[QuestionType.fillBlank]!.acceptedAnswers, isNotEmpty);
    expect(byType[QuestionType.matching]!.pairs, isNotEmpty);
    expect(byType[QuestionType.creative]!.parts, isNotEmpty);
    expect(qs.where((q) => q.boardId != null).every((q) => !q.boardId!.startsWith('brd-')), isTrue);
    // Round-trips through local storage.
    for (final q in qs) {
      expect(Question.fromJson(q.toJson()).id, q.id);
    }
  });

  test('cached catalog becomes the active curriculum; books follow it', () {
    CatalogSync.apply(_syncedStore().get(CatalogSync.collection, CatalogSync.curriculumKey)!);
    expect(seedSubjects.map((s) => s.id), unorderedEquals(['ssc-physics', 'ssc-math']));
    expect(subjectById('ssc-physics'), isNotNull);
    expect(sampleBooks.map((b) => b.id), contains('book-ssc-physics'));
    CurriculumCatalog.reset();
    expect(seedSubjects.any((s) => s.id == 'ssc-phy'), isTrue);
  });

  test('synced questions replace the bundled bank', () {
    final c = testContainer(store: _syncedStore());
    final ids = c.read(questionRepositoryProvider).cached.map((q) => q.id).toSet();
    expect(ids, unorderedEquals({for (final q in _list('questions')) q['id']}));
    expect(ids.contains('q-phy-f6'), isFalse); // a bundled-only question
  });

  group('screens on the server curriculum', () {
    setUp(() => CatalogSync.apply(_syncedStore().get(CatalogSync.collection, CatalogSync.curriculumKey)!));

    for (final (name, screen) in [
      ('learn', const LearnScreen()),
      ('chapter', const ChapterDetailScreen(chapterId: 'ssc-physics-c1')),
      ('question bank', const QuestionBankScreen(subjectId: 'ssc-physics')),
      ('exam setup', const ExamSetupScreen()),
      ('dashboard', const StudentHomeScreen()),
      ('analytics', const AnalyticsScreen()),
      ('library', const LibraryScreen()),
    ]) {
      testWidgets('$name renders', (tester) async {
        await tester.pumpWidget(testApp(screen, store: _syncedStore(), lang: AppLanguage.en));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
