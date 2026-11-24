import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router/app_routes.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/rich_content.dart';
import '../../shared/widgets/section_header.dart';
import '../curriculum/domain/curriculum_models.dart';
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
  static const boardLabel = Tr('বোর্ড', 'Board');
  static const year = Tr('বছর', 'Year');
  static const subject = Tr('বিষয়', 'Subject');
  static const allSubjects = Tr('সব বিষয়', 'All subjects');
  static const questions = Tr('{n}টি প্রশ্ন', '{n} questions');
  static const noPapers = Tr('এই ফিল্টারে কোনো প্রশ্নপত্র নেই', 'No papers for these filters');
  static const frequency = Tr('বারবার আসা অধ্যায় (নমুনা ফ্রিকোয়েন্সি)', 'Most repeated chapters (sample frequency)');
  static const institution = Tr('স্কুল-কলেজের প্রশ্ন', 'School & college papers');
  static const institutionHint = Tr(
    'বিভিন্ন স্কুল-কলেজের পরীক্ষার প্রশ্ন (ডেমো প্রতিষ্ঠান ও নমুনা প্রশ্ন)।',
    'Exam papers from schools and colleges (demo institutions and sample questions).',
  );
  static const searchInstitution = Tr('প্রতিষ্ঠান খুঁজুন', 'Search institutions');
  static const district = Tr('জেলা', 'District');
  static const school = Tr('স্কুল', 'School');
  static const college = Tr('কলেজ', 'College');
  static const all = Tr('সব', 'All');
  static const practise = Tr('এই প্রশ্নপত্র অনুশীলন করো', 'Practise this paper');
  static const sample = Tr('বোর্ড-ধাঁচের নমুনা', 'Board-style sample');
  static const verified = Tr('যাচাইকৃত সমাধান', 'Verified solutions');
}

List<Question> _bank(WidgetRef ref) => ref.watch(questionRepositoryProvider).cached;

/// Board-style sample papers with board/year/subject filters and a frequency view.
class BoardArchiveScreen extends ConsumerStatefulWidget {
  const BoardArchiveScreen({super.key});

  @override
  ConsumerState<BoardArchiveScreen> createState() => _BoardArchiveScreenState();
}

class _BoardArchiveScreenState extends ConsumerState<BoardArchiveScreen> {
  late String _board = ref.read(studentProfileProvider).boardId;
  int _year = archiveYears.first;
  String? _subjectId;

  @override
  Widget build(BuildContext context) {
    final bank = _bank(ref);
    final level = ref.watch(studentProfileProvider.select((p) => p.level));
    final subjects = [for (final s in seedSubjects) if (s.level == level) s];
    final papers = [
      for (final s in subjects)
        if (_subjectId == null || s.id == _subjectId)
          ?boardPaper(bank, subject: s, boardId: _board, year: _year),
    ];
    final freq = <String, (Chapter, int)>{};
    for (final q in bank) {
      final s = subjectById(q.subjectId);
      if (s == null || s.level != level) continue;
      final c = s.chapters.where((c) => c.id == q.chapterId).firstOrNull;
      if (c == null) continue;
      freq[c.id] = (c, (freq[c.id]?.$2 ?? 0) + q.frequency);
    }
    final top = freq.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final maxFreq = top.isEmpty ? 1 : top.first.$2;
    return DefaultTabController(
      length: 2,
      child: AppPageScaffold(
        title: context.tr(ArchiveStrings.board),
        scrollable: false,
        bottom: TabBar(tabAlignment: TabAlignment.fill, tabs: [Tab(text: context.tr(ArchiveStrings.papers)), Tab(text: context.tr(ArchiveStrings.insights))]),
        body: TabBarView(
          children: [
            ListView(
              children: [
                InfoBanner(message: context.tr(ArchiveStrings.boardHint)),
                const SizedBox(height: AppSpacing.md),
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
                  isExpanded: true,
                  initialValue: _subjectId,
                  decoration: InputDecoration(labelText: context.tr(ArchiveStrings.subject)),
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.tr(ArchiveStrings.allSubjects))),
                    for (final s in subjects) DropdownMenuItem(value: s.id, child: Text(context.tr(s.name))),
                  ],
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
                const SizedBox(height: AppSpacing.md),
                if (papers.isEmpty) EmptyState(title: context.tr(ArchiveStrings.noPapers), icon: Icons.history_edu_outlined, compact: true),
                for (final p in papers) _PaperTile(paper: p),
              ],
            ),
            ListView(
              children: [
                SectionHeader(title: context.tr(ArchiveStrings.frequency)),
                for (final (c, f) in top.take(10))
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperTile extends StatelessWidget {
  const _PaperTile({required this.paper});

  final ArchivePaper paper;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        key: Key('paper.${paper.id}'),
        leading: IconTile(icon: paper.subject.icon, color: paper.subject.color),
        title: Text(context.tr(paper.title)),
        subtitle: Text([
          if (paper.institution != null) context.tr(paper.institution!.name),
          context.tr(ArchiveStrings.questions.fill({'n': paper.questionIds.length})),
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(paper.isBoard ? AppRoutes.boardPaper(paper.id) : AppRoutes.institutionPaper(paper.id)),
      ),
    );
  }
}

/// Directory of (demo) schools/colleges and their papers.
class InstitutionArchiveScreen extends ConsumerStatefulWidget {
  const InstitutionArchiveScreen({super.key});

  @override
  ConsumerState<InstitutionArchiveScreen> createState() => _InstitutionArchiveScreenState();
}

class _InstitutionArchiveScreenState extends ConsumerState<InstitutionArchiveScreen> {
  String _q = '';
  bool? _college;

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final papers = [
      for (final p in institutionPapers(_bank(ref)))
        if ((_college == null || p.institution!.college == _college) &&
            (q.isEmpty || p.institution!.name.matches(q) || p.institution!.district.matches(q) || p.title.matches(q)))
          p,
    ];
    return AppPageScaffold(
      title: context.tr(ArchiveStrings.institution),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(ArchiveStrings.institutionHint), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('inst.search'),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: context.tr(ArchiveStrings.searchInstitution)),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          ChoiceChipBar<bool?>(
            options: const [null, false, true],
            selected: _college,
            labelOf: (v) => context.tr(v == null ? ArchiveStrings.all : (v ? ArchiveStrings.college : ArchiveStrings.school)),
            onSelected: (v) => setState(() => _college = v),
          ),
          const SizedBox(height: AppSpacing.md),
          if (papers.isEmpty) EmptyState(title: context.tr(ArchiveStrings.noPapers), icon: Icons.account_balance_outlined, compact: true),
          for (final p in papers) _PaperTile(paper: p),
        ],
      ),
    );
  }
}

/// One paper: its questions, a sample label and "practise this paper".
class ArchivePaperScreen extends ConsumerWidget {
  const ArchivePaperScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = _bank(ref);
    final paper = paperById(bank, paperId);
    if (paper == null) return AppPageScaffold(title: context.tr(ArchiveStrings.papers), body: const ErrorView());
    final questions = [for (final id in paper.questionIds) ?bank.where((q) => q.id == id).firstOrNull];
    final text = Theme.of(context).textTheme;
    return AppPageScaffold(
      title: context.tr(paper.subject.name),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(paper.title), style: text.titleMedium),
          if (paper.institution != null) Text('${context.tr(paper.institution!.name)} · ${context.tr(paper.institution!.district)} · ${context.n(paper.year)}', style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              if (paper.isBoard) Pill(context.tr(ArchiveStrings.sample), tone: Tone.warning),
              if (paper.category != null) Pill(context.tr(paper.category!.label)),
              Pill(context.tr(ArchiveStrings.verified), tone: Tone.success, icon: Icons.verified_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('paper.practise'),
            onPressed: () async {
              final set = await ref.read(practiceProvider.notifier).createSet(context.tr(paper.title), questionIds: paper.questionIds);
              if (context.mounted) await context.push(Uri(path: '/practice-session', queryParameters: {'mode': 'set', 'set': set.id}).toString());
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(context.tr(ArchiveStrings.practise)),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (i, q) in questions.indexed)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () => context.push(AppRoutes.question(q.id)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${context.n(i + 1)}. ${context.tr(q.type.label)} · ${context.n(q.marks)}', style: text.labelMedium),
                      const SizedBox(height: AppSpacing.xs),
                      RichContent(context.tr(q.stem)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
