import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../../../mock/seed/curriculum_seed.dart';
import '../../../mock/seed/tutor_knowledge_seed.dart';
import '../../curriculum/domain/curriculum_models.dart';

/// One searchable page of a sample textbook.
class BookPage {
  const BookPage({required this.page, required this.chapterId, required this.chapterTitle, required this.heading, required this.body});

  final int page;
  final String chapterId;
  final Tr chapterTitle;
  final Tr heading;
  final Tr body;
}

/// A sample textbook (one per curriculum subject). Synthetic content written for the demo,
/// clearly labelled — not a real NCTB book.
class Book {
  const Book({required this.subject, required this.pages, required this.scenarios});

  final Subject subject;
  final List<BookPage> pages;

  /// Detailed passages (definitions, formulas, examples) printed in this book.
  final List<TutorScenario> scenarios;

  String get id => 'book-${subject.id}';
  Tr get title => Tr('${subject.name.bn} (নমুনা পাঠ্যবই)', '${subject.name.en} (sample textbook)');
  EducationLevel get level => subject.level;
  Color get color => subject.color;
  IconData get icon => subject.icon;
  List<Chapter> get chapters => subject.chapters;

  /// 'bn' | 'en' — English books are written (and spoken) in English.
  String get language => subject.id.contains('-eng') ? 'en' : 'bn';

  Chapter? chapter(String id) => chapters.where((c) => c.id == id).firstOrNull;

  /// First printed page of a chapter (table of contents).
  int? firstPageOf(String chapterId) {
    int? first;
    for (final p in pages) {
      if (p.chapterId == chapterId && (first == null || p.page < first)) first = p.page;
    }
    return first;
  }

  int get pageCount => pages.isEmpty ? 0 : pages.last.page;

  /// Index of the page with this printed number (or the nearest one after it).
  int indexOfPage(int number) {
    final i = pages.indexWhere((p) => p.page >= number);
    return i < 0 ? pages.length - 1 : i;
  }
}

Book _buildBook(Subject subject) {
  final scenarios = [for (final s in tutorScenarios) if (s.subjectId == subject.id) s];
  // Detailed passages keep their printed page numbers; generated pages fill the rest.
  final reserved = {for (final s in scenarios) s.page};
  String passage(TutorScenario s, AppLanguage l) {
    final formula = s.formula == null ? '' : '\n\n\$\$${s.formula}\$\$';
    return '${s.excerpt.of(l)}\n\n${s.definition.of(l)}$formula\n\n${l == AppLanguage.bn ? 'উদাহরণ' : 'Example'}: ${s.example.of(l)}';
  }

  final pages = <BookPage>[
    for (final s in scenarios)
      BookPage(
        page: s.page,
        chapterId: s.chapterId,
        chapterTitle: subject.chapters.where((c) => c.id == s.chapterId).firstOrNull?.title ?? s.title,
        heading: s.title,
        body: Tr(passage(s, AppLanguage.bn), passage(s, AppLanguage.en)),
      ),
  ];
  var page = 3;
  int next() {
    while (reserved.contains(page)) {
      page++;
    }
    return page++;
  }

  for (final chapter in subject.chapters) {
    pages.add(BookPage(page: next(), chapterId: chapter.id, chapterTitle: chapter.title, heading: chapter.title, body: chapter.description));
    for (final topic in chapter.topics) {
      final outcomes = topic.outcomes;
      pages.add(BookPage(
        page: next(),
        chapterId: chapter.id,
        chapterTitle: chapter.title,
        heading: topic.title,
        body: Tr(
          '${topic.title.bn}: ${chapter.description.bn} এই অংশ পড়ে তুমি — ${outcomes.map((o) => o.text.bn).join('; ')}।',
          '${topic.title.en}: ${chapter.description.en} After this section you can — ${outcomes.map((o) => o.text.en).join('; ')}.',
        ),
      ));
      next();
    }
  }
  pages.sort((a, b) => a.page.compareTo(b.page));
  return Book(subject: subject, pages: pages, scenarios: scenarios);
}

/// All sample textbooks, built once from the curriculum seed.
final List<Book> sampleBooks = [for (final s in seedSubjects) _buildBook(s)];

Book? bookById(String id) => sampleBooks.where((b) => b.id == id).firstOrNull;
