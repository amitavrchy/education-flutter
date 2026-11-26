import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/tr.dart';
import '../domain/curriculum_models.dart';

/// The curriculum every screen reads (through `seedSubjects` / `subjectById`).
///
/// Mock mode keeps the bundled sample curriculum. API mode swaps in the backend's curriculum
/// (synced by `CatalogSync`), so ids match the server's progress, exams and questions.
abstract final class CurriculumCatalog {
  static List<Subject>? _subjects;
  static List<Subject> Function() _bundled = () => const [];

  /// Bumped on every swap so derived caches (books, indexes) can rebuild.
  static int version = 0;

  /// Set once by the bundled seed.
  static void registerBundled(List<Subject> Function() bundled) => _bundled = bundled;

  static List<Subject> get subjects => _subjects ?? _bundled();

  static bool get fromServer => _subjects != null;

  static void use(List<Subject> subjects) {
    _subjects = subjects;
    version++;
  }

  /// Back to the bundled curriculum (tests, mock mode).
  static void reset() {
    _subjects = null;
    version++;
  }
}

/// Icon and colour per backend subject icon key.
const _looks = <String, (IconData, Color)>{
  'physics': (Icons.bolt, Color(0xFF3B82F6)),
  'chemistry': (Icons.science, Color(0xFF10B981)),
  'biology': (Icons.biotech, Color(0xFF22C55E)),
  'math': (Icons.calculate, Color(0xFF8B5CF6)),
  'higher-math': (Icons.functions, Color(0xFF6366F1)),
  'bangla': (Icons.menu_book, Color(0xFFEF4444)),
  'english': (Icons.translate, Color(0xFFF59E0B)),
  'ict': (Icons.computer, Color(0xFF06B6D4)),
  'accounting': (Icons.account_balance_wallet, Color(0xFF14B8A6)),
  'finance': (Icons.savings, Color(0xFF0EA5E9)),
  'economics': (Icons.trending_up, Color(0xFFF97316)),
  'civics': (Icons.gavel, Color(0xFF64748B)),
  'geography': (Icons.public, Color(0xFF84CC16)),
  'history': (Icons.history_edu, Color(0xFFA16207)),
};

Tr _tr(Object? v) => Tr.fromJson(v);

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) => values.where((v) => v.name == name).firstOrNull ?? fallback;

/// Builds app subjects from the backend's `/subjects`, `/papers`, `/chapters`, `/topics` and
/// `/outcomes` lists (raw JSON, as cached by `CatalogSync`).
List<Subject> subjectsFromApi({
  required List<Map<String, dynamic>> subjects,
  required List<Map<String, dynamic>> papers,
  required List<Map<String, dynamic>> chapters,
  required List<Map<String, dynamic>> topics,
  required List<Map<String, dynamic>> outcomes,
}) {
  final paperNo = {for (final p in papers) p['id'] as String: (p['number'] as num?)?.toInt() ?? 1};
  final outcomesByTopic = <String, List<LearningOutcome>>{};
  for (final o in outcomes) {
    (outcomesByTopic[o['topicId'] as String] ??= []).add(LearningOutcome(id: o['id'] as String, text: _tr(o['text'])));
  }
  final topicsByChapter = <String, List<Map<String, dynamic>>>{};
  for (final t in topics) {
    (topicsByChapter[t['chapterId'] as String] ??= []).add(t);
  }
  final chaptersBySubject = <String, List<Chapter>>{};
  for (final c in chapters) {
    if (c['status'] != null && c['status'] != 'published') continue;
    final id = c['id'] as String;
    final minutes = (c['estimatedMinutes'] as num?)?.toInt() ?? 240;
    final ts = [...?topicsByChapter[id]]..sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
    (chaptersBySubject[c['subjectId'] as String] ??= []).add(Chapter(
      id: id,
      subjectId: c['subjectId'] as String,
      number: (c['number'] as num?)?.toInt() ?? 1,
      paper: paperNo[c['paperId']] ?? 1,
      title: _tr(c['title']),
      description: _tr(c['description']),
      minutes: minutes,
      difficulty: _enum(Difficulty.values, c['difficulty'], Difficulty.medium),
      relevance: _enum(ExamRelevance.values, c['examRelevance'], ExamRelevance.medium),
      prerequisiteIds: [for (final p in c['prerequisiteIds'] as List? ?? const []) p as String],
      topics: [
        for (final (i, t) in ts.indexed)
          Topic(
            id: t['id'] as String,
            chapterId: id,
            number: (t['order'] as num?)?.toInt() ?? i + 1,
            title: _tr(t['title']),
            outcomes: outcomesByTopic[t['id']] ?? const [],
            minutes: ts.isEmpty ? 30 : (minutes / ts.length).round(),
          ),
      ],
    ));
  }
  final out = <Subject>[];
  for (final s in subjects) {
    if (s['status'] != null && s['status'] != 'published') continue;
    final id = s['id'] as String;
    final (icon, color) = _looks[s['icon']] ?? (Icons.menu_book_outlined, const Color(0xFF64748B));
    final chs = [...?chaptersBySubject[id]]..sort((a, b) => a.paper != b.paper ? a.paper.compareTo(b.paper) : a.number.compareTo(b.number));
    out.add(Subject(
      id: id,
      code: s['code'] as String? ?? '',
      level: EducationLevel.fromCode(s['levelCode'] as String? ?? 'SSC'),
      name: _tr(s['name']),
      groups: [for (final g in s['groupCodes'] as List? ?? const []) ?AcademicGroup.values.where((x) => x.name == g).firstOrNull],
      color: color,
      icon: icon,
      chapters: chs,
      description: _tr(s['description']),
      papers: papers.where((p) => p['subjectId'] == id).length.clamp(1, 3),
      compulsory: s['compulsory'] as bool? ?? false,
    ));
  }
  return out;
}

/// Questions whose chapter exists in [subjects]; the rest would show without a chapter
/// (the server currently has a few for a chapter it doesn't publish).
List<Map<String, dynamic>> questionsWithKnownChapter(List<Map<String, dynamic>> questions, List<Subject> subjects) {
  final chapters = {for (final s in subjects) for (final c in s.chapters) c.id};
  return [for (final q in questions) if (chapters.contains(q['chapterId'])) q];
}
