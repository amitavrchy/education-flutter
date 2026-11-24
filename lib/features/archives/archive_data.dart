import '../../core/l10n/tr.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../book_avatar/application/avatar_controller.dart' show mixHash;
import '../curriculum/domain/curriculum_models.dart';
import '../question_bank/domain/question.dart';

/// Exam categories for school/college papers.
enum PaperCategory {
  halfYearly(Tr('অর্ধবার্ষিক', 'Half-yearly')),
  annual(Tr('বার্ষিক', 'Annual')),
  test(Tr('টেস্ট', 'Test')),
  preTest(Tr('প্রি-টেস্ট', 'Pre-test')),
  selection(Tr('নির্বাচনী', 'Selection')),
  model(Tr('মডেল টেস্ট', 'Model test'));

  const PaperCategory(this.label);
  final Tr label;
}

class DemoInstitution {
  const DemoInstitution(this.id, this.name, this.district, this.college);

  final String id;
  final Tr name;
  final Tr district;
  final bool college;
}

/// Fictional schools and colleges (demo directory — not real institutions).
const demoInstitutions = [
  DemoInstitution('inst-1', Tr('আইডিয়াল মডেল হাই স্কুল (ডেমো)', 'Ideal Model High School (demo)'), Tr('ঢাকা', 'Dhaka'), false),
  DemoInstitution('inst-2', Tr('নদীতীর সরকারি কলেজ (ডেমো)', 'Riverside Govt College (demo)'), Tr('রাজশাহী', 'Rajshahi'), true),
  DemoInstitution('inst-3', Tr('সবুজবাগ বালিকা বিদ্যালয় (ডেমো)', 'Sabujbagh Girls School (demo)'), Tr('চট্টগ্রাম', 'Chattogram'), false),
  DemoInstitution('inst-4', Tr('পাহাড়পুর উচ্চ বিদ্যালয় (ডেমো)', 'Paharpur High School (demo)'), Tr('সিলেট', 'Sylhet'), false),
  DemoInstitution('inst-5', Tr('মেঘনা কলেজ (ডেমো)', 'Meghna College (demo)'), Tr('কুমিল্লা', 'Cumilla'), true),
  DemoInstitution('inst-6', Tr('সূর্যোদয় স্কুল অ্যান্ড কলেজ (ডেমো)', 'Sunrise School & College (demo)'), Tr('খুলনা', 'Khulna'), true),
];

/// A question paper assembled from the question bank. Board papers are **board-style samples**
/// (synthetic), never copies of real board papers.
class ArchivePaper {
  const ArchivePaper({
    required this.id,
    required this.title,
    required this.subject,
    required this.year,
    required this.questionIds,
    this.boardId,
    this.institution,
    this.category,
  });

  final String id;
  final Tr title;
  final Subject subject;
  final int year;
  final List<String> questionIds;
  final String? boardId;
  final DemoInstitution? institution;
  final PaperCategory? category;

  bool get isBoard => boardId != null;
}

const archiveYears = [2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015];

/// Deterministic pick of up to [n] questions of a subject for a paper.
List<String> _pick(List<Question> bank, Subject s, String seed, {int n = 8, String? boardId, int? year}) {
  final mine = [for (final q in bank) if (q.subjectId == s.id) q];
  // Real board-tagged samples of this board/year come first.
  final tagged = [for (final q in mine) if (boardId != null && q.boardId == boardId && q.year == year) q.id];
  final rest = [for (final q in mine) if (!tagged.contains(q.id)) q]..sort((a, b) => mixHash('$seed${a.id}').compareTo(mixHash('$seed${b.id}')));
  return [...tagged, ...rest.map((q) => q.id)].take(n).toList();
}

/// Board-style sample paper (null when the subject has no questions yet, or HSC 2020).
ArchivePaper? boardPaper(List<Question> bank, {required Subject subject, required String boardId, required int year}) {
  if (subject.level == EducationLevel.hsc && year == 2020) return null; // No HSC exam was held in 2020.
  final id = 'bp-$boardId-$year-${subject.id}';
  final ids = _pick(bank, subject, id, boardId: boardId, year: year);
  if (ids.isEmpty) return null;
  final board = educationBoards.where((b) => b.id == boardId).firstOrNull;
  return ArchivePaper(
    id: id,
    title: Tr('${subject.name.bn} — ${board?.name.bn ?? boardId} বোর্ড $year', '${subject.name.en} — ${board?.name.en ?? boardId} board $year'),
    subject: subject,
    year: year,
    boardId: boardId,
    questionIds: ids,
  );
}

/// School/college papers of the demo directory (two per institution and subject level).
List<ArchivePaper> institutionPapers(List<Question> bank) => [
  for (final inst in demoInstitutions)
    for (final s in seedSubjects.where((s) => s.level == (inst.college ? EducationLevel.hsc : EducationLevel.ssc)).take(4))
      for (final (i, cat) in [PaperCategory.values[mixHash('${inst.id}${s.id}') % 3], PaperCategory.values[3 + mixHash('${s.id}${inst.id}') % 3]].indexed)
        if (_pick(bank, s, '${inst.id}-${s.id}-$i', n: 6) case final ids when ids.isNotEmpty)
          ArchivePaper(
            id: 'ip-${inst.id}-${s.id}-$i',
            title: Tr('${s.name.bn} — ${cat.label.bn} পরীক্ষা', '${s.name.en} — ${cat.label.en} exam'),
            subject: s,
            year: 2025 - i,
            institution: inst,
            category: cat,
            questionIds: ids,
          ),
];

ArchivePaper? paperById(List<Question> bank, String id) {
  if (id.startsWith('bp-')) {
    final parts = id.split('-');
    final subjectId = parts.sublist(3).join('-');
    final subject = subjectById(subjectId);
    if (subject == null) return null;
    return boardPaper(bank, subject: subject, boardId: parts[1], year: int.parse(parts[2]));
  }
  return institutionPapers(bank).where((p) => p.id == id).firstOrNull;
}
