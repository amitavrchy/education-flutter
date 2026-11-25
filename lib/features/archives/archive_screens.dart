import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../curriculum/domain/curriculum_models.dart';
import '../exams/application/exam_controller.dart';
import '../exams/domain/exam.dart';
import '../profile/application/student_profile_controller.dart';
import '../question_bank/application/practice_controller.dart';
import '../question_bank/data/question_repository.dart';
import '../question_bank/domain/question.dart';
import 'archive_data.dart';

abstract final class ArchiveStrings {
  static const board = Tr('বোর্ড প্রশ্ন আর্কাইভ', 'Board question archive');
  static const boardHint = Tr(
    '৯ বোর্ড × ১০ বছরের বোর্ড-ধাঁচের নমুনা প্রশ্নপত্র। এগুলো ডেমোর জন্য তৈরি কৃত্রিম নমুনা, আসল বোর্ড প্রশ্ন নয়।',
    'Board-style sample papers for 9 boards × 10 years. These are synthetic samples for the demo, not real board papers.',
  );
  static const papers = Tr('প্রশ্নপত্র', 'Papers');
  static const insights = Tr('বিশ্লেষণ', 'Insights');
  static const saved = Tr('সংরক্ষিত', 'Saved');
  static const boardLabel = Tr('বোর্ড', 'Board');
  static const year = Tr('বছর', 'Year');
  static const level = Tr('স্তর', 'Level');
  static const curriculum = Tr('শিক্ষাক্রম', 'Curriculum');
  static const examType = Tr('পরীক্ষার ধরন', 'Exam type');
  static const subject = Tr('বিষয়', 'Subject');
  static const allSubjects = Tr('সব বিষয়', 'All subjects');
  static const questions = Tr('{n}টি প্রশ্ন', '{n} questions');
  static const noPapers = Tr('এই ফিল্টারে কোনো প্রশ্নপত্র নেই', 'No papers for these filters');
  static const hsc2020 = Tr('২০২০ সালে এইচএসসি পরীক্ষা হয়নি — তাই কোনো পত্র নেই।', 'No HSC exam was held in 2020, so there are no papers.');
  static const frequency = Tr('বারবার আসা অধ্যায় (নমুনা ফ্রিকোয়েন্সি)', 'Most repeated chapters (sample frequency)');
  static const trends = Tr('ঐতিহাসিক ধারা (অধ্যায় × বছর)', 'Historical trends (chapter × year)');
  static const repeated = Tr('বারবার আসা ধারণা', 'Repeated concepts');
  static const yearsN = Tr('{n} বছরে এসেছে', 'appeared in {n} years');
  static const clusters = Tr('একই ধরনের প্রশ্নের গুচ্ছ', 'Similar question clusters');
  static const pattern = Tr('প্রশ্নের প্যাটার্ন', 'Exam pattern');
  static const compare = Tr('বছরভিত্তিক তুলনা', 'Compare across years');
  static const institution = Tr('স্কুল-কলেজের প্রশ্ন', 'School & college papers');
  static const institutionHint = Tr('বিভিন্ন স্কুল-কলেজের পরীক্ষার প্রশ্ন (ডেমো প্রতিষ্ঠান ও নমুনা প্রশ্ন)।', 'Exam papers from schools and colleges (demo institutions and sample questions).');
  static const searchInstitution = Tr('প্রতিষ্ঠান খুঁজুন', 'Search institutions');
  static const district = Tr('জেলা', 'District');
  static const school = Tr('স্কুল', 'School');
  static const college = Tr('কলেজ', 'College');
  static const category = Tr('পরীক্ষার ধরন', 'Exam category');
  static const all = Tr('সব', 'All');
  static const directory = Tr('প্রতিষ্ঠানের তালিকা', 'Institution directory');
  static const collection = Tr('{n}টি প্রশ্নপত্র', '{n} papers');
  static const practise = Tr('অনুশীলন', 'Practise');
  static const timed = Tr('সময় ধরে পরীক্ষা', 'Timed exam');
  static const minutes = Tr('{n} মিনিট', '{n} min');
  static const solved = Tr('সমাধানসহ দেখাও', 'Show solutions');
  static const answerSheet = Tr('MCQ উত্তরপত্র', 'MCQ answer sheet');
  static const save = Tr('সংরক্ষণ', 'Save');
  static const savedNote = Tr('প্রশ্নপত্র সংরক্ষিত', 'Paper saved');
  static const unsaved = Tr('সংরক্ষণ বাতিল', 'Removed from saved');
  static const copy = Tr('ডাউনলোড (কপি)', 'Download (copy)');
  static const copied = Tr('প্রশ্নপত্র কপি হয়েছে — যেকোনো অ্যাপে পেস্ট বা প্রিন্ট করো', 'Paper copied — paste or print it anywhere');
  static const explain = Tr('AI ব্যাখ্যা', 'AI explanation');
  static const bookmark = Tr('বুকমার্ক', 'Bookmark');
  static const sample = Tr('বোর্ড-ধাঁচের নমুনা (কৃত্রিম)', 'Board-style sample (synthetic)');
  static const verified = Tr('যাচাইকৃত সমাধান', 'Verified solutions');
  static const authenticity = Tr('উৎস ও অনুমতি', 'Source & permission');
  static const source = Tr('উৎস', 'Source');
  static const sourceValue = Tr('ডেমোর জন্য তৈরি কৃত্রিম নমুনা', 'Synthetic sample made for the demo');
  static const status = Tr('অবস্থা', 'Status');
  static const statusValue = Tr('শিক্ষক যাচাইকৃত', 'Teacher verified');
  static const scan = Tr('স্ক্যান', 'Scan');
  static const scanValue = Tr('নেই — টাইপ করা ট্রান্সক্রিপ্ট', 'None — typed transcript');
  static const permission = Tr('অনুমতি', 'Permission');
  static const permissionValue = Tr('শিক্ষার জন্য প্রদর্শন ও অনুশীলন', 'Display and practice for learning');
  static const private = Tr('শুধু প্রতিষ্ঠানের শিক্ষার্থীদের জন্য', 'Only for students of this institution');
  static const privateLocked = Tr('এই প্রশ্নপত্র প্রতিষ্ঠানটি ব্যক্তিগত রেখেছে। তোমার প্রোফাইলে এই প্রতিষ্ঠান থাকলে দেখতে পাবে।', 'The institution keeps this paper private. You can see it if this institution is on your profile.');
  static const public = Tr('সবার জন্য', 'Public');
  static const teacherUploaded = Tr('শিক্ষকের আপলোড', 'Teacher uploaded');
  static const duplicate = Tr('সম্ভাব্য ডুপ্লিকেট: {t}', 'Possible duplicate: {t}');
  static const viewScan = Tr('স্ক্যান দেখো', 'View scan');
  static const scanNote = Tr('নমুনা স্ক্যান (সিমুলেটেড) — আসল প্রশ্নপত্রের ছবি নয়।', 'Sample scan (simulated) — not a photo of a real paper.');
  static const report = Tr('রিপোর্ট', 'Report');
  static const reported = Tr('রিপোর্ট পাঠানো হয়েছে — কনটেন্ট দল দেখবে', 'Report sent — the content team will check it');
  static const reportReasons = [
    Tr('ভুল উত্তর', 'Wrong answer'),
    Tr('অস্পষ্ট প্রশ্ন', 'Unclear question'),
    Tr('কপিরাইট সমস্যা', 'Copyright concern'),
    Tr('ডুপ্লিকেট', 'Duplicate'),
  ];
  static const relatedSets = Tr('সম্পর্কিত অনুশীলন', 'Related practice');
  static const chapterPractice = Tr('“{c}” অধ্যায় অনুশীলন', 'Practise “{c}”');
  static const noSaved = Tr('কোনো সংরক্ষিত প্রশ্নপত্র নেই', 'No saved papers');
}

List<Question> _bank(WidgetRef ref) => ref.watch(questionRepositoryProvider).cached;

Chapter? _chapterOf(Question q) => subjectById(q.subjectId)?.chapters.where((c) => c.id == q.chapterId).firstOrNull;

/// Board-style sample papers with level, board, year, subject, edition and exam-type filters,
/// plus insights (frequency, trends, repeated concepts, clusters) and saved papers.
class BoardArchiveScreen extends ConsumerStatefulWidget {
  const BoardArchiveScreen({super.key});

  @override
  ConsumerState<BoardArchiveScreen> createState() => _BoardArchiveScreenState();
}

class _BoardArchiveScreenState extends ConsumerState<BoardArchiveScreen> {
  late String _board = ref.read(studentProfileProvider).boardId;
  late EducationLevel _level = ref.read(studentProfileProvider).level;
  late String _edition = ref.read(studentProfileProvider).curriculumVersionId;
  BoardExamType _type = BoardExamType.regular;
  int _year = archiveYears.first;
  String? _subjectId;

  @override
  Widget build(BuildContext context) {
    final bank = _bank(ref);
    final subjects = [for (final s in seedSubjects) if (s.level == _level) s];
    // Older editions only have papers up to 2018; supplementary sittings cover fewer subjects.
    final editionOk = _edition == 'nctb-2025' ? _year >= 2019 : _year < 2019;
    final papers = [
      if (editionOk)
        for (final (i, s) in subjects.indexed)
          if ((_subjectId == null || s.id == _subjectId) && (_type == BoardExamType.regular || i.isEven)) ?boardPaper(bank, subject: s, boardId: _board, year: _year),
    ];
    final saved = ref.watch(archiveProvider).saved;
    return DefaultTabController(
      length: 3,
      child: AppPageScaffold(
        title: context.tr(ArchiveStrings.board),
        scrollable: false,
        bottom: TabBar(
          tabAlignment: TabAlignment.fill,
          tabs: [Tab(text: context.tr(ArchiveStrings.papers)), Tab(text: context.tr(ArchiveStrings.insights)), Tab(text: '${context.tr(ArchiveStrings.saved)} (${context.n(saved.length)})')],
        ),
        body: TabBarView(
          children: [
            ListView(
              children: [
                InfoBanner(message: context.tr(ArchiveStrings.boardHint)),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<EducationLevel>(
                  segments: [for (final l in EducationLevel.values) ButtonSegment(value: l, label: Text(l.code))],
                  selected: {_level},
                  onSelectionChanged: (v) => setState(() {
                    _level = v.first;
                    _subjectId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _board,
                        decoration: InputDecoration(labelText: context.tr(ArchiveStrings.boardLabel)),
                        items: [for (final b in educationBoards) DropdownMenuItem(value: b.id, child: Text(context.tr(b.name)))],
                        onChanged: (v) => setState(() => _board = v ?? _board),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        key: const Key('board.year'),
                        initialValue: _year,
                        decoration: InputDecoration(labelText: context.tr(ArchiveStrings.year)),
                        items: [for (final y in archiveYears) DropdownMenuItem(value: y, child: Text(context.n(y)))],
                        onChanged: (v) => setState(() => _year = v ?? _year),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String?>(
                  key: ValueKey('subj-${_level.name}'),
                  isExpanded: true,
                  initialValue: _subjectId,
                  decoration: InputDecoration(labelText: context.tr(ArchiveStrings.subject)),
                  items: [
                    DropdownMenuItem(child: Text(context.tr(ArchiveStrings.allSubjects))),
                    for (final s in subjects) DropdownMenuItem(value: s.id, child: Text(context.tr(s.name))),
                  ],
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _edition,
                        decoration: InputDecoration(labelText: context.tr(ArchiveStrings.curriculum)),
                        items: [for (final v in curriculumVersions) DropdownMenuItem(value: v.id, child: Text(context.tr(v.name), overflow: TextOverflow.ellipsis))],
                        onChanged: (v) => setState(() => _edition = v ?? _edition),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<BoardExamType>(
                        isExpanded: true,
                        initialValue: _type,
                        decoration: InputDecoration(labelText: context.tr(ArchiveStrings.examType)),
                        items: [for (final t in BoardExamType.values) DropdownMenuItem(value: t, child: Text(context.tr(t.label)))],
                        onChanged: (v) => setState(() => _type = v ?? _type),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_level == EducationLevel.hsc && _year == 2020)
                  InfoBanner(message: context.tr(ArchiveStrings.hsc2020), tone: Tone.info)
                else if (papers.isEmpty)
                  EmptyState(title: context.tr(ArchiveStrings.noPapers), icon: Icons.history_edu_outlined, compact: true),
                for (final p in papers) _PaperTile(paper: p),
              ],
            ),
            _BoardInsights(level: _level, board: _board, subjectId: _subjectId),
            ListView(
              children: [
                if (saved.isEmpty) EmptyState(title: context.tr(ArchiveStrings.noSaved), icon: Icons.bookmark_border),
                for (final id in saved)
                  if (paperById(bank, id) case final p?) _PaperTile(paper: p),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardInsights extends ConsumerWidget {
  const _BoardInsights({required this.level, required this.board, this.subjectId});

  final EducationLevel level;
  final String board;
  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = _bank(ref);
    final subjects = [for (final s in seedSubjects) if (s.level == level && (subjectId == null || s.id == subjectId)) s];
    // Chapter frequency from question frequency tags.
    final freq = <String, (Chapter, int)>{};
    for (final q in bank) {
      final s = subjectById(q.subjectId);
      if (s == null || !subjects.contains(s)) continue;
      final c = _chapterOf(q);
      if (c == null) continue;
      freq[c.id] = (c, (freq[c.id]?.$2 ?? 0) + q.frequency);
    }
    final top = freq.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final maxFreq = top.isEmpty ? 1 : math.max(1, top.first.$2);
    // Trends & repeated concepts from the generated papers (last 5 years).
    final years = archiveYears.take(5).toList();
    final perYear = <String, Map<int, int>>{};
    final topicYears = <String, Set<int>>{};
    for (final y in years) {
      for (final s in subjects) {
        final p = boardPaper(bank, subject: s, boardId: board, year: y);
        if (p == null) continue;
        for (final id in p.questionIds) {
          final q = bank.where((x) => x.id == id).firstOrNull;
          if (q == null) continue;
          (perYear[q.chapterId] ??= {}).update(y, (v) => v + 1, ifAbsent: () => 1);
          (topicYears[q.topicId] ??= {}).add(y);
        }
      }
    }
    final trendChapters = top.take(5).map((e) => e.$1).toList();
    final repeated = [for (final e in topicYears.entries) if (e.value.length >= 3) e]..sort((a, b) => b.value.length.compareTo(a.value.length));
    final clusters = <String, List<Question>>{};
    for (final q in bank) {
      if (subjects.any((s) => s.id == q.subjectId)) (clusters['${q.chapterId}|${q.type.name}'] ??= []).add(q);
    }
    final bigClusters = [for (final e in clusters.entries) if (e.value.length >= 3) e]..sort((a, b) => b.value.length.compareTo(a.value.length));
    final topicTitle = {for (final s in subjects) for (final c in s.chapters) for (final t in c.topics) t.id: t.title};
    return ListView(
      children: [
        SectionHeader(title: context.tr(ArchiveStrings.frequency)),
        for (final (c, f) in top.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(c.title)),
                const SizedBox(height: AppSpacing.xxs),
                LinearProgressIndicator(value: f / maxFreq, minHeight: 6, borderRadius: BorderRadius.circular(3)),
              ],
            ),
          ),
        SectionHeader(title: context.tr(ArchiveStrings.trends)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            columns: [
              DataColumn(label: Text(context.tr(ArchiveStrings.subject))),
              for (final y in years.reversed) DataColumn(label: Text(context.n(y)), numeric: true),
            ],
            rows: [
              for (final c in trendChapters)
                DataRow(cells: [
                  DataCell(SizedBox(width: 140, child: Text(context.tr(c.title), overflow: TextOverflow.ellipsis))),
                  for (final y in years.reversed) DataCell(Text(context.n(perYear[c.id]?[y] ?? 0))),
                ]),
            ],
          ),
        ),
        SectionHeader(title: context.tr(ArchiveStrings.repeated)),
        if (repeated.isEmpty) Text('—', style: Theme.of(context).textTheme.bodySmall),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final e in repeated.take(8))
              if (topicTitle[e.key] case final t?) Pill('${context.tr(t)} · ${context.tr(ArchiveStrings.yearsN.fill({'n': e.value.length}))}', tone: Tone.info),
          ],
        ),
        SectionHeader(title: context.tr(ArchiveStrings.clusters)),
        for (final e in bigClusters.take(5))
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('${context.tr(_chapterOf(e.value.first)?.title ?? const Tr.same('—'))} · ${context.tr(e.value.first.type.label)}'),
            subtitle: Text(context.tr(ArchiveStrings.questions.fill({'n': e.value.length}))),
            children: [
              for (final q in e.value.take(4))
                ListTile(dense: true, title: Text(context.tr(q.stem), maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => context.push(AppRoutes.question(q.id))),
            ],
          ),
      ],
    );
  }
}

class _PaperTile extends ConsumerWidget {
  const _PaperTile({required this.paper});

  final ArchivePaper paper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(archiveProvider).saved.contains(paper.id);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        key: Key('paper.${paper.id}'),
        leading: IconTile(icon: paper.subject.icon, color: paper.subject.color),
        title: Text(context.tr(paper.title)),
        subtitle: Text([
          if (paper.institution != null) context.tr(paper.institution!.name),
          context.tr(ArchiveStrings.questions.fill({'n': paper.questionIds.length})),
          if (paperIsPrivate(paper)) context.tr(ArchiveStrings.private),
        ].join(' · ')),
        trailing: Icon(saved ? Icons.bookmark : Icons.chevron_right),
        onTap: () => context.push(paper.isBoard ? AppRoutes.boardPaper(paper.id) : AppRoutes.institutionPaper(paper.id)),
      ),
    );
  }
}

/// Directory of (demo) schools/colleges with search and district, type, year, class,
/// subject and category filters; papers grouped as institution collections.
class InstitutionArchiveScreen extends ConsumerStatefulWidget {
  const InstitutionArchiveScreen({super.key});

  @override
  ConsumerState<InstitutionArchiveScreen> createState() => _InstitutionArchiveScreenState();
}

class _InstitutionArchiveScreenState extends ConsumerState<InstitutionArchiveScreen> {
  String _q = '';
  bool? _college;
  String? _district;
  int? _year;
  String? _subjectId;
  PaperCategory? _category;

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final all = institutionPapers(_bank(ref));
    final districts = {for (final i in demoInstitutions) i.district.en: i.district};
    final subjects = {for (final p in all) p.subject.id: p.subject};
    final papers = [
      for (final p in all)
        if ((_college == null || p.institution!.college == _college) &&
            (_district == null || p.institution!.district.en == _district) &&
            (_year == null || p.year == _year) &&
            (_subjectId == null || p.subject.id == _subjectId) &&
            (_category == null || p.category == _category) &&
            (q.isEmpty || p.institution!.name.matches(q) || p.institution!.district.matches(q) || p.title.matches(q)))
          p,
    ];
    final byInst = <DemoInstitution, List<ArchivePaper>>{};
    for (final p in papers) {
      (byInst[p.institution!] ??= []).add(p);
    }
    Widget drop<T>(Tr label, T? value, List<(T, String)> items, ValueChanged<T?> onChanged) => DropdownButtonFormField<T?>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: context.tr(label), isDense: true),
      items: [DropdownMenuItem<T?>(child: Text(context.tr(ArchiveStrings.all))), for (final (v, l) in items) DropdownMenuItem<T?>(value: v, child: Text(l, overflow: TextOverflow.ellipsis))],
      onChanged: onChanged,
    );
    return AppPageScaffold(
      title: context.tr(ArchiveStrings.institution),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(ArchiveStrings.institutionHint), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(key: const Key('inst.search'), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr(ArchiveStrings.searchInstitution)), onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: AppSpacing.sm),
          ChoiceChipBar<bool?>(
            options: const [null, false, true],
            selected: _college,
            labelOf: (v) => context.tr(v == null ? ArchiveStrings.all : (v ? ArchiveStrings.college : ArchiveStrings.school)),
            onSelected: (v) => setState(() => _college = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: drop<String>(ArchiveStrings.district, _district, [for (final e in districts.entries) (e.key, context.tr(e.value))], (v) => setState(() => _district = v))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: drop<int>(ArchiveStrings.year, _year, [for (final y in const [2025, 2024]) (y, context.n(y))], (v) => setState(() => _year = v))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: drop<String>(ArchiveStrings.subject, _subjectId, [for (final s in subjects.values) (s.id, '${context.tr(s.name)} (${s.level.code})')], (v) => setState(() => _subjectId = v))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: drop<PaperCategory>(ArchiveStrings.category, _category, [for (final c in PaperCategory.values) (c, context.tr(c.label))], (v) => setState(() => _category = v))),
            ],
          ),
          SectionHeader(title: context.tr(ArchiveStrings.directory)),
          if (papers.isEmpty) EmptyState(title: context.tr(ArchiveStrings.noPapers), icon: Icons.account_balance_outlined, compact: true),
          for (final e in byInst.entries)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExpansionTile(
                key: Key('inst.${e.key.id}'),
                initiallyExpanded: byInst.length <= 2,
                leading: Icon(e.key.college ? Icons.account_balance : Icons.school_outlined),
                title: Text(context.tr(e.key.name)),
                subtitle: Text('${context.tr(e.key.district)} · ${context.tr(ArchiveStrings.collection.fill({'n': e.value.length}))}'),
                children: [for (final p in e.value) Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: _PaperTile(paper: p))],
              ),
            ),
        ],
      ),
    );
  }
}

/// One paper: authenticity, practise / timed exam, solved view with MCQ answer sheet,
/// bookmarks, AI explanation, save, download, compare years, pattern, report.
class ArchivePaperScreen extends ConsumerStatefulWidget {
  const ArchivePaperScreen({super.key, required this.paperId});

  final String paperId;

  @override
  ConsumerState<ArchivePaperScreen> createState() => _ArchivePaperScreenState();
}

class _ArchivePaperScreenState extends ConsumerState<ArchivePaperScreen> {
  bool _solved = false;

  Future<void> _timed(ArchivePaper paper, List<Question> questions) async {
    final minutes = math.max(10, questions.fold<int>(0, (s, q) => s + q.marks) * 2);
    try {
      final attempt = await ref.read(examProvider.notifier).start(
        template: ExamTemplate(
          id: 'tmpl-${paper.id}',
          type: paper.isBoard ? ExamType.boardPrevious : ExamType.custom,
          title: paper.title,
          config: ExamConfig(subjectId: paper.subject.id, questionCount: questions.length, timeLimitMinutes: minutes, randomize: false),
          questionIds: paper.questionIds,
        ),
      );
      if (mounted) await context.push(AppRoutes.examTake(attempt.id));
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    }
  }

  String _plain(ArchivePaper paper, List<Question> qs) => [
    context.tr(paper.title),
    if (paper.isBoard) context.tr(ArchiveStrings.sample),
    '',
    for (final (i, q) in qs.indexed) ...[
      '${i + 1}. ${context.tr(q.stem)}',
      for (final (j, o) in q.options.indexed) '   ${String.fromCharCode(0x0995 + j)}) ${context.tr(o)}',
      if (_solved) '   → ${context.tr(q.answer)}',
    ],
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    final bank = _bank(ref);
    final paper = paperById(bank, widget.paperId);
    if (paper == null) return AppPageScaffold(title: context.tr(ArchiveStrings.papers), body: const ErrorView());
    final questions = [for (final id in paper.questionIds) ?bank.where((q) => q.id == id).firstOrNull];
    final text = Theme.of(context).textTheme;
    final archive = ref.watch(archiveProvider);
    final bookmarks = ref.watch(practiceProvider).bookmarks;
    final profileInst = ref.watch(studentProfileProvider.select((p) => p.institution));
    final locked = paperIsPrivate(paper) && !(paper.institution?.name.matches(profileInst) ?? false || profileInst.isEmpty);
    final dup = paper.isBoard ? null : duplicateOf(paper, institutionPapers(bank));
    final mcqs = [for (final (i, q) in questions.indexed) if (q.type == QuestionType.mcq && q.correctIndex != null) (i, q)];
    final byType = <QuestionType, (int, int)>{};
    for (final q in questions) {
      final e = byType[q.type] ?? (0, 0);
      byType[q.type] = (e.$1 + 1, e.$2 + q.marks);
    }
    final chapters = <String, Chapter>{};
    for (final q in questions) {
      final c = _chapterOf(q);
      if (c != null) chapters[c.id] = c;
    }
    final compareYears = paper.isBoard ? [paper.year, paper.year - 1, paper.year - 2].where(archiveYears.contains).toList() : const <int>[];
    return AppPageScaffold(
      title: context.tr(paper.subject.name),
      actions: [
        IconButton(
          key: const Key('paper.save'),
          tooltip: context.tr(ArchiveStrings.save),
          icon: Icon(archive.saved.contains(paper.id) ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () async {
            final on = await ref.read(archiveProvider.notifier).toggleSaved(paper.id);
            if (context.mounted) context.showSnack(on ? ArchiveStrings.savedNote : ArchiveStrings.unsaved);
          },
        ),
        PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'copy') {
              await Clipboard.setData(ClipboardData(text: _plain(paper, questions)));
              if (context.mounted) context.showSnack(ArchiveStrings.copied);
            }
            if (v == 'report' && context.mounted) {
              final reason = await showReportDialog(context, reasons: ArchiveStrings.reportReasons);
              if (reason != null) {
                await ref.read(archiveProvider.notifier).report(paper.id, reason);
                if (context.mounted) context.showSnack(ArchiveStrings.reported);
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'copy', child: Text(context.tr(ArchiveStrings.copy))),
            PopupMenuItem(value: 'report', child: Text(context.tr(ArchiveStrings.report))),
          ],
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(paper.title), style: text.titleMedium),
          if (paper.institution != null) Text('${context.tr(paper.institution!.name)} · ${context.tr(paper.institution!.district)} · ${context.n(paper.year)}', style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (paper.isBoard) Pill(context.tr(ArchiveStrings.sample), tone: Tone.warning),
              if (paper.category != null) Pill(context.tr(paper.category!.label)),
              if (!paper.isBoard) Pill(context.tr(paperIsPrivate(paper) ? ArchiveStrings.private : ArchiveStrings.public), icon: paperIsPrivate(paper) ? Icons.lock_outline : Icons.public),
              if (paperTeacherUploaded(paper)) Pill(context.tr(ArchiveStrings.teacherUploaded), tone: Tone.info, icon: Icons.upload_file),
              Pill(context.tr(ArchiveStrings.verified), tone: Tone.success, icon: Icons.verified_outlined),
              if (archive.reported.containsKey(paper.id)) Pill(context.tr(ArchiveStrings.reported), tone: Tone.neutral, icon: Icons.flag_outlined),
            ],
          ),
          if (dup != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(message: context.tr(ArchiveStrings.duplicate.fill({'t': context.tr(dup.title)})), tone: Tone.warning, icon: Icons.copy_all_outlined),
          ],
          if (locked) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(key: const Key('paper.locked'), message: context.tr(ArchiveStrings.privateLocked), icon: Icons.lock_outline),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('paper.practise'),
                    onPressed: () async {
                      final set = await ref.read(practiceProvider.notifier).createSet(context.tr(paper.title), questionIds: paper.questionIds);
                      if (context.mounted) await context.push(Uri(path: '/practice-session', queryParameters: {'mode': 'set', 'set': set.id}).toString());
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(context.tr(ArchiveStrings.practise)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('paper.timed'),
                    onPressed: () => _timed(paper, questions),
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(context.tr(ArchiveStrings.timed)),
                  ),
                ),
              ],
            ),
            if (!paper.isBoard)
              TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(ctx.tr(ArchiveStrings.viewScan)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 260,
                          width: double.maxFinite,
                          color: Colors.grey.shade200,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(_plain(paper, questions.take(3).toList()), style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(ctx.tr(ArchiveStrings.scanNote), style: Theme.of(ctx).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(context.tr(ArchiveStrings.viewScan)),
              ),
            SwitchListTile(key: const Key('paper.solved'), contentPadding: EdgeInsets.zero, title: Text(context.tr(ArchiveStrings.solved)), value: _solved, onChanged: (v) => setState(() => _solved = v)),
            if (_solved && mcqs.isNotEmpty) ...[
              Text(context.tr(ArchiveStrings.answerSheet), style: text.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [for (final (i, q) in mcqs) Chip(label: Text('${context.n(i + 1)} → ${String.fromCharCode(0x0995 + q.correctIndex!)}'), visualDensity: VisualDensity.compact)],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final (i, q) in questions.indexed)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  onTap: () => context.push(AppRoutes.question(q.id)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${context.n(i + 1)}. ${context.tr(q.type.label)} · ${context.n(q.marks)}', style: text.labelMedium)),
                            IconButton(
                              key: Key('paper.bm.${q.id}'),
                              tooltip: context.tr(ArchiveStrings.bookmark),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(bookmarks.contains(q.id) ? Icons.bookmark : Icons.bookmark_border, size: 20),
                              onPressed: () => ref.read(practiceProvider.notifier).toggleBookmark(q.id),
                            ),
                            IconButton(
                              tooltip: context.tr(ArchiveStrings.explain),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.auto_awesome_outlined, size: 20),
                              onPressed: () => context.go(AppRoutes.tutor(subjectId: q.subjectId, chapterId: q.chapterId, prompt: context.tr(q.stem))),
                            ),
                          ],
                        ),
                        RichContent(context.tr(q.stem)),
                        if (_chapterOf(q) case final c?) Padding(padding: const EdgeInsets.only(top: 4), child: Pill(context.tr(c.title))),
                        if (_solved) ...[
                          const Divider(),
                          if (q.parts.isNotEmpty)
                            for (final part in q.parts) Text('${part.label}) ${context.tr(part.answer)}', style: text.bodySmall)
                          else
                            RichContent(context.tr(q.answer)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            SectionHeader(title: context.tr(ArchiveStrings.pattern)),
            for (final e in byType.entries)
              KeyValueRow(context.tr(e.key.label), '${context.tr(ArchiveStrings.questions.fill({'n': e.value.$1}))} · ${context.n(e.value.$2)}'),
            if (compareYears.length > 1) ...[
              SectionHeader(title: context.tr(ArchiveStrings.compare)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: [DataColumn(label: Text(context.tr(ArchiveStrings.subject))), for (final y in compareYears) DataColumn(label: Text(context.n(y)), numeric: true)],
                  rows: [
                    for (final c in chapters.values)
                      DataRow(cells: [
                        DataCell(SizedBox(width: 140, child: Text(context.tr(c.title), overflow: TextOverflow.ellipsis))),
                        for (final y in compareYears)
                          DataCell(Text(context.n(
                            (boardPaper(bank, subject: paper.subject, boardId: paper.boardId!, year: y)?.questionIds ?? const <String>[])
                                .where((id) => bank.where((q) => q.id == id).firstOrNull?.chapterId == c.id)
                                .length,
                          ))),
                      ]),
                  ],
                ),
              ),
            ],
            SectionHeader(title: context.tr(ArchiveStrings.relatedSets)),
            for (final c in chapters.values.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.quiz_outlined),
                title: Text(context.tr(ArchiveStrings.chapterPractice.fill({'c': context.tr(c.title)}))),
                onTap: () => context.push(AppRoutes.practiceSession(subjectId: paper.subject.id, chapterId: c.id)),
              ),
          ],
          SectionHeader(title: context.tr(ArchiveStrings.authenticity)),
          KeyValueRow(context.tr(ArchiveStrings.source), context.tr(ArchiveStrings.sourceValue)),
          KeyValueRow(context.tr(ArchiveStrings.status), context.tr(ArchiveStrings.statusValue)),
          KeyValueRow(context.tr(ArchiveStrings.scan), context.tr(ArchiveStrings.scanValue)),
          KeyValueRow(context.tr(ArchiveStrings.permission), context.tr(ArchiveStrings.permissionValue)),
        ],
      ),
    );
  }
}
