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
}

Book _buildBook(Subject subject) {
  final pages = <BookPage>[];
  var page = 3;
  for (final chapter in subject.chapters) {
    pages.add(BookPage(
      page: page++,
      chapterId: chapter.id,
      chapterTitle: chapter.title,
      heading: chapter.title,
      body: chapter.description,
    ));
    for (final topic in chapter.topics) {
      final outcomes = topic.outcomes;
      pages.add(BookPage(
        page: page,
        chapterId: chapter.id,
        chapterTitle: chapter.title,
        heading: topic.title,
        body: Tr(
          '${topic.title.bn}: ${chapter.description.bn} এই অংশ পড়ে তুমি — ${outcomes.map((o) => o.text.bn).join('; ')}।',
          '${topic.title.en}: ${chapter.description.en} After this section you can — ${outcomes.map((o) => o.text.en).join('; ')}.',
        ),
      ));
      page += 2;
    }
  }
  return Book(subject: subject, pages: pages, scenarios: [for (final s in tutorScenarios) if (s.subjectId == subject.id) s]);
}

/// All sample textbooks, built once from the curriculum seed.
final List<Book> sampleBooks = [for (final s in seedSubjects) _buildBook(s)];

Book? bookById(String id) => sampleBooks.where((b) => b.id == id).firstOrNull;
