import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/common_strings.dart';
import '../../core/l10n/tr.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/time_format.dart';
import '../../mock/seed/curriculum_seed.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/progress.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../curriculum/domain/curriculum_models.dart';
import '../question_bank/data/question_repository.dart';
import '../question_bank/domain/question.dart';
import 'review_data.dart';
import 'teacher_screens.dart' show defaultTeacherSubjectId;
import 'teacher_data.dart';

abstract final class WStr {
  static const review = Tr('কনটেন্ট পর্যালোচনা', 'Content review');
  static const reviewSub = Tr('প্রশ্ন, উত্তর ও কনটেন্ট যাচাই করুন — সংশোধন প্রস্তাব, মন্তব্য, অনুমোদন', 'Verify questions, answers and content — suggest fixes, comment, approve');
  static const actingAs = Tr('যে ভূমিকায় কাজ করছেন', 'Acting as');
  static const actingNote = Tr('শিক্ষক জমা দেন; পর্যালোচক শুরু, অনুমোদন বা পরিবর্তন চান; প্রকাশ ও আর্কাইভ কনটেন্ট ম্যানেজার (ওয়েব) করেন।', 'Teachers submit; reviewers start, approve or request changes; content managers (web) publish and archive.');
  static const waiting = Tr('অপেক্ষমাণ', 'Waiting');
  static const all = Tr('সব', 'All');
  static const queueEmpty = Tr('কিউ খালি', 'Queue is empty');
  static const flow = Tr('কনটেন্টের অবস্থা', 'Content status flow');
  static const priority = Tr('অগ্রাধিকার', 'Priority');
  static const due = Tr('সময়সীমা', 'Due');
  static const submittedBy = Tr('জমাদাতা', 'Submitted by');
  static const content = Tr('কনটেন্ট', 'Content');
  static const decide = Tr('পরবর্তী ধাপ', 'Next step');
  static const note = Tr('সিদ্ধান্তের নোট (পরিবর্তন চাইলে আবশ্যক)', 'Decision note (required to request changes)');
  static const locked = Tr('আপনার ভূমিকায় এই ধাপ নেই', 'Not available for your role');
  static const updated = Tr('হালনাগাদ হয়েছে', 'Updated');
  static const comments = Tr('মন্তব্য', 'Comments');
  static const writeComment = Tr('মন্তব্য লিখুন', 'Write a comment');
  static const suggestions = Tr('সংশোধনের প্রস্তাব', 'Suggested corrections');
  static const suggest = Tr('প্রস্তাব', 'Suggest');
  static const currentText = Tr('বর্তমান লেখা', 'Current text');
  static const suggestedText = Tr('প্রস্তাবিত লেখা', 'Suggested text');
  static const suggestionAdded = Tr('সংশোধনের প্রস্তাব যোগ হয়েছে', 'Suggestion added');
  static const accept = Tr('গ্রহণ', 'Accept');
  static const reject = Tr('বাতিল', 'Reject');
  static const accepted = Tr('গৃহীত', 'Accepted');
  static const rejected = Tr('বাতিল', 'Rejected');
  static const history = Tr('ইতিহাস', 'History');
  static const historyTitle = Tr('পর্যালোচনার ইতিহাস', 'Review history');
  static const historySub = Tr('আপনার জমা দেওয়া ও পর্যালোচিত সব কনটেন্ট', 'Everything you submitted or reviewed');
  static const noHistory = Tr('এখনো কিছু নেই', 'Nothing yet');
  static const questions = Tr('প্রশ্ন তৈরি ও সম্পাদনা', 'Create & edit questions');
  static const newQuestion = Tr('নতুন প্রশ্ন', 'New question');
  static const editQuestion = Tr('প্রশ্ন সম্পাদনা', 'Edit question');
  static const noQuestions = Tr('এখনো কোনো প্রশ্ন লেখেননি', "You haven't written any questions yet");
  static const stem = Tr('প্রশ্ন', 'Question');
  static const answer = Tr('উত্তর', 'Answer');
  static const explanation = Tr('ব্যাখ্যা (ঐচ্ছিক)', 'Explanation (optional)');
  static const options = Tr('অপশন (প্রতি লাইনে একটি)', 'Options (one per line)');
  static const correct = Tr('সঠিক অপশন', 'Correct option');
  static const type = Tr('ধরন', 'Type');
  static const subject = Tr('বিষয়', 'Subject');
  static const chapter = Tr('অধ্যায়', 'Chapter');
  static const difficulty = Tr('কঠিনতা', 'Difficulty');
  static const marks = Tr('নম্বর', 'Marks');
  static const saveDraft = Tr('খসড়া সংরক্ষণ', 'Save draft');
  static const submitReview = Tr('পর্যালোচনায় জমা', 'Submit for review');
  static const draftSaved = Tr('খসড়া সংরক্ষিত', 'Draft saved');
  static const submitted = Tr('পর্যালোচনায় জমা হয়েছে', 'Submitted for review');
  static const needStem = Tr('প্রশ্ন ও উত্তর লিখুন', 'Write the question and the answer');
  static const needOptions = Tr('অন্তত দুটি অপশন দিন', 'Give at least two options');
  static const version = Tr('সংস্করণ {n}', 'Version {n}');
  static const rubrics = Tr('রুব্রিক ব্যবস্থাপনা', 'Rubric management');
  static const newRubric = Tr('নতুন রুব্রিক', 'New rubric');
  static const editRubric = Tr('রুব্রিক সম্পাদনা', 'Edit rubric');
  static const rubricName = Tr('রুব্রিকের নাম', 'Rubric name');
  static const appliesTo = Tr('প্রযোজ্য', 'Applies to');
  static const allSubjects = Tr('সব বিষয়', 'All subjects');
  static const criterion = Tr('মানদণ্ড', 'Criterion');
  static const description = Tr('বিবরণ', 'Description');
  static const total = Tr('মোট', 'Total');
  static const rubricSaved = Tr('রুব্রিক সংরক্ষিত', 'Rubric saved');
  static const subjects = Tr('নির্ধারিত বিষয়', 'Assigned subjects');
  static const chapters = Tr('অধ্যায়', 'Chapters');
  static const bankQuestions = Tr('প্রশ্নব্যাংকে প্রশ্ন', 'Questions in bank');
  static const classes = Tr('ক্লাস', 'Classes');
  static const openReviews = Tr('খোলা পর্যালোচনা', 'Open reviews');
  static const students = Tr('শিক্ষার্থীদের পারফরম্যান্স', 'Student performance');
  static const studentsSub = Tr('আপনার শ্রেণির শিক্ষার্থী — সংক্ষিপ্ত পরিসংখ্যান (ডেমো)', 'Students in your classes — summary statistics (demo)');
  static const searchStudents = Tr('শিক্ষার্থী খুঁজুন', 'Search students');
  static const needsHelp = Tr('সাহায্য দরকার', 'Needs help');
  static const onTrack = Tr('ঠিক পথে', 'On track');
  static const mastery = Tr('দক্ষতা', 'Mastery');
  static const sendFeedback = Tr('মতামত পাঠান', 'Send feedback');
  static const feedbackSent = Tr('মতামত পাঠানো হয়েছে — শিক্ষার্থী ও অভিভাবক দেখতে পাবেন', 'Feedback sent — the student and guardian can see it');
  static const work = Tr('জমা দেওয়া কাজ', 'Submitted work');
  static const submissions = Tr('শিক্ষার্থীদের জমা', 'Student submissions');
  static const submittedLabel = Tr('জমা দিয়েছে', 'Submitted');
  static const lateLabel = Tr('দেরিতে', 'Late');
  static const missingLabel = Tr('জমা দেয়নি', 'Missing');
  static const grade = Tr('নম্বর দিন', 'Grade');
  static const graded = Tr('নম্বর দেওয়া হয়েছে', 'Graded');
  static const remind = Tr('রিমাইন্ডার পাঠান', 'Send reminder');
  static const reminded = Tr('যারা জমা দেয়নি তাদের রিমাইন্ডার পাঠানো হয়েছে (ডেমো)', 'Reminder sent to students who have not submitted (demo)');
  static const feedback = Tr('মতামত', 'Feedback');
}

Tone _statusTone(ContentStatus s) => switch (s) {
  ContentStatus.draft => Tone.neutral,
  ContentStatus.submitted => Tone.info,
  ContentStatus.inReview => Tone.primary,
  ContentStatus.changesRequested => Tone.warning,
  ContentStatus.approved => Tone.success,
  ContentStatus.published => Tone.success,
  ContentStatus.archived => Tone.neutral,
};

Tone _priorityTone(ReviewPriority p) => switch (p) {
  ReviewPriority.urgent => Tone.danger,
  ReviewPriority.high => Tone.warning,
  _ => Tone.neutral,
};

String _subjectName(BuildContext context, String id) => subjectById(id) == null ? id : context.tr(subjectById(id)!.name);

/// Teacher / reviewer role switch (TCH-23).
class ActingRoleBar extends ConsumerWidget {
  const ActingRoleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acting = ref.watch(reviewProvider.select((s) => s.actingAs));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr(WStr.actingAs), style: context.text.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<ActorRole>(
          key: const Key('review.acting'),
          segments: [
            ButtonSegment(value: ActorRole.teacher, label: Text(context.tr(ActorRole.teacher.label)), icon: const Icon(Icons.school_outlined)),
            ButtonSegment(value: ActorRole.reviewer, label: Text(context.tr(ActorRole.reviewer.label)), icon: const Icon(Icons.verified_user_outlined)),
          ],
          selected: {acting},
          onSelectionChanged: (s) => ref.read(reviewProvider.notifier).actAs(s.first),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(context.tr(WStr.actingNote), style: context.text.bodySmall),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.item});

  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final overdue = item.dueAt != null && item.dueAt!.isBefore(DateTime.now()) && item.status.index < ContentStatus.approved.index;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        key: Key('review.${item.id}'),
        leading: Icon(item.kind.icon),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Pill(context.tr(item.status.label), tone: _statusTone(item.status)),
              if (item.priority.index >= ReviewPriority.high.index) Pill(context.tr(item.priority.label), tone: _priorityTone(item.priority)),
              if (item.dueAt != null) Pill('${context.tr(WStr.due)}: ${shortDate(item.dueAt!, context.lang)}', tone: overdue ? Tone.danger : Tone.neutral),
            ],
          ),
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReviewItemScreen(id: item.id))),
      ),
    );
  }
}

/// Content review queue (TCH-03).
class TeacherReviewScreen extends ConsumerStatefulWidget {
  const TeacherReviewScreen({super.key});

  @override
  ConsumerState<TeacherReviewScreen> createState() => _TeacherReviewScreenState();
}

class _TeacherReviewScreenState extends ConsumerState<TeacherReviewScreen> {
  ContentStatus? _status;
  ReviewKind? _kind;
  bool _waiting = true;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(reviewProvider);
    final items = [
      for (final i in (_waiting ? s.queue : s.items))
        if ((_status == null || i.status == _status) && (_kind == null || i.kind == _kind)) i,
    ]..sort((a, b) {
        final p = b.priority.index.compareTo(a.priority.index);
        return p != 0 ? p : (a.dueAt ?? DateTime(2100)).compareTo(b.dueAt ?? DateTime(2100));
      });
    return AppPageScaffold(
      title: context.tr(WStr.review),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(WStr.reviewSub), style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          const ActingRoleBar(),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text('${context.tr(WStr.waiting)} (${context.n(s.queue.length)})')),
              ButtonSegment(value: false, label: Text('${context.tr(WStr.all)} (${context.n(s.items.length)})')),
            ],
            selected: {_waiting},
            onSelectionChanged: (v) => setState(() {
              _waiting = v.first;
              _status = null;
            }),
          ),
          if (!_waiting)
            ChoiceChipBar<ContentStatus?>(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              options: [null, ...ContentStatus.values],
              selected: _status,
              labelOf: (x) => context.tr(x?.label ?? WStr.all),
              onSelected: (x) => setState(() => _status = x),
            ),
          ChoiceChipBar<ReviewKind?>(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            options: [null, ...ReviewKind.values],
            selected: _kind,
            labelOf: (x) => context.tr(x?.label ?? WStr.all),
            onSelected: (x) => setState(() => _kind = x),
          ),
          if (items.isEmpty) EmptyState(icon: Icons.inbox_outlined, title: context.tr(WStr.queueEmpty)),
          for (final i in items) _ReviewTile(item: i),
        ],
      ),
    );
  }
}

/// One review item (TCH-04..09, TCH-22): preview, status flow, decision, comments,
/// suggested corrections and the history timeline.
class ReviewItemScreen extends ConsumerStatefulWidget {
  const ReviewItemScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReviewItemScreen> createState() => _ReviewItemScreenState();
}

class _ReviewItemScreenState extends ConsumerState<ReviewItemScreen> {
  final _note = TextEditingController();
  final _comment = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, Tr ok) async {
    try {
      await action();
      if (mounted) context.showSnack(ok);
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    }
  }

  Future<void> _suggest(ReviewItem item) async {
    final result = await showDialog<(String, String)>(context: context, builder: (_) => _SuggestDialog(preview: item.preview));
    if (result == null) return;
    await _run(() => ref.read(reviewProvider.notifier).suggest(item.id, result.$1, result.$2), WStr.suggestionAdded);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(reviewProvider);
    final item = s.item(widget.id);
    if (item == null) return AppPageScaffold(title: context.tr(WStr.review), body: EmptyState(title: context.tr(S.notFound), icon: Icons.search_off));
    final c = ref.read(reviewProvider.notifier);
    final next = contentTransitions[item.status]!;
    final allowed = allowedTransitions(item.status, s.actingAs);
    return AppPageScaffold(
      title: context.tr(item.kind.label),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.title, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Pill(context.tr(item.status.label), tone: _statusTone(item.status), icon: item.status.icon),
              Pill('${context.tr(WStr.priority)}: ${context.tr(item.priority.label)}', tone: _priorityTone(item.priority)),
              Pill(_subjectName(context, item.subjectId)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          KeyValueRow(context.tr(WStr.submittedBy), '${item.submittedBy.name} (${context.tr(item.submittedBy.role.label)})'),
          if (item.dueAt != null) KeyValueRow(context.tr(WStr.due), shortDate(item.dueAt!, context.lang)),
          SectionHeader(title: context.tr(WStr.flow)),
          _StatusFlow(current: item.status),
          SectionHeader(title: context.tr(WStr.content)),
          Card(
            key: const Key('review.preview'),
            margin: EdgeInsets.zero,
            child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: SelectableText(item.preview)),
          ),
          SectionHeader(title: context.tr(WStr.decide)),
          const ActingRoleBar(),
          const SizedBox(height: AppSpacing.sm),
          TextField(key: const Key('review.note'), controller: _note, maxLines: 2, decoration: InputDecoration(labelText: context.tr(WStr.note))),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final to in next)
                Tooltip(
                  message: allowed.contains(to) ? '' : context.tr(WStr.locked),
                  child: FilledButton.tonalIcon(
                    key: Key('review.to.${to.name}'),
                    onPressed: allowed.contains(to)
                        ? () => _run(() async {
                              await c.transition(item.id, to, note: _note.text);
                              _note.clear();
                            }, WStr.updated)
                        : null,
                    icon: Icon(allowed.contains(to) ? to.icon : Icons.lock_outline),
                    label: Text(context.tr(to.label)),
                  ),
                ),
            ],
          ),
          SectionHeader(title: context.tr(WStr.suggestions), actionLabel: context.tr(WStr.suggest), onAction: () => _suggest(item)),
          if (item.suggestions.isEmpty) Text('—', style: context.text.bodySmall),
          for (final sg in item.suggestions)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sg.from, style: context.text.bodyMedium?.copyWith(decoration: TextDecoration.lineThrough, color: context.palette.danger)),
                    Text(sg.to, style: context.text.bodyMedium?.copyWith(color: context.palette.success)),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(child: Text('${sg.by.name} · ${relativeTime(sg.at, context.lang)}', style: context.text.labelSmall)),
                        if (sg.state == SuggestionState.open) ...[
                          TextButton(onPressed: () => c.resolveSuggestion(item.id, sg.id, accept: false), child: Text(context.tr(WStr.reject))),
                          FilledButton(key: Key('sg.accept.${sg.id}'), onPressed: () => c.resolveSuggestion(item.id, sg.id, accept: true), child: Text(context.tr(WStr.accept))),
                        ] else
                          Pill(context.tr(sg.state == SuggestionState.accepted ? WStr.accepted : WStr.rejected), tone: sg.state == SuggestionState.accepted ? Tone.success : Tone.neutral),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          SectionHeader(title: '${context.tr(WStr.comments)} (${context.n(item.comments.length)})'),
          for (final cm in item.comments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(cm.author.name.characters.first)),
              title: Text(cm.text),
              subtitle: Text('${cm.author.name} · ${relativeTime(cm.at, context.lang)}'),
            ),
          Row(
            children: [
              Expanded(child: TextField(key: const Key('review.comment'), controller: _comment, decoration: InputDecoration(hintText: context.tr(WStr.writeComment)))),
              IconButton(
                key: const Key('review.send'),
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (_comment.text.trim().isEmpty) return;
                  await c.comment(item.id, _comment.text);
                  _comment.clear();
                },
              ),
            ],
          ),
          SectionHeader(title: context.tr(WStr.history)),
          for (final e in item.history.reversed)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(e.to.icon, size: 20),
              title: Text('${e.from == null ? '' : '${context.tr(e.from!.label)} → '}${context.tr(e.to.label)}'),
              subtitle: Text('${e.by.name} · ${relativeTime(e.at, context.lang)}${e.note == null ? '' : ' · ${e.note}'}'),
            ),
        ],
      ),
    );
  }
}

class _StatusFlow extends StatelessWidget {
  const _StatusFlow({required this.current});

  final ContentStatus current;

  @override
  Widget build(BuildContext context) {
    const main = [ContentStatus.draft, ContentStatus.submitted, ContentStatus.inReview, ContentStatus.approved, ContentStatus.published];
    final reached = current == ContentStatus.archived ? main.length : main.indexOf(current);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, st) in main.indexed) ...[
            if (i > 0) Icon(Icons.chevron_right, size: 16, color: context.colors.outline),
            Pill(
              context.tr(st.label),
              tone: st == current ? Tone.primary : (reached >= 0 && i < reached ? Tone.success : Tone.neutral),
              icon: st == current ? Icons.radio_button_checked : null,
            ),
          ],
          if (current == ContentStatus.changesRequested || current == ContentStatus.archived) ...[
            const SizedBox(width: AppSpacing.sm),
            Pill(context.tr(current.label), tone: current == ContentStatus.changesRequested ? Tone.warning : Tone.neutral, icon: current.icon),
          ],
        ],
      ),
    );
  }
}

class _SuggestDialog extends StatefulWidget {
  const _SuggestDialog({required this.preview});

  final String preview;

  @override
  State<_SuggestDialog> createState() => _SuggestDialogState();
}

class _SuggestDialogState extends State<_SuggestDialog> {
  final _from = TextEditingController();
  final _to = TextEditingController();

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(WStr.suggestions)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(key: const Key('sg.from'), controller: _from, maxLines: 2, decoration: InputDecoration(labelText: context.tr(WStr.currentText))),
        const SizedBox(height: AppSpacing.sm),
        TextField(key: const Key('sg.to'), controller: _to, maxLines: 2, decoration: InputDecoration(labelText: context.tr(WStr.suggestedText))),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr(S.cancel))),
      FilledButton(key: const Key('sg.save'), onPressed: () => Navigator.pop(context, (_from.text, _to.text)), child: Text(context.tr(WStr.suggest))),
    ],
  );
}

/// Everything submitted or reviewed by this teacher (TCH-19).
class TeacherHistoryScreen extends ConsumerWidget {
  const TeacherHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(reviewProvider).items;
    final mine = [
      for (final i in items)
        if (i.submittedBy.name == teacherActor.name || i.history.any((e) => e.by.name == teacherActor.name || e.by.name == reviewerActor.name)) i,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final approved = mine.where((i) => i.status == ContentStatus.approved || i.status == ContentStatus.published).length;
    final changes = mine.where((i) => i.status == ContentStatus.changesRequested).length;
    return AppPageScaffold(
      title: context.tr(WStr.historyTitle),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(WStr.historySub), style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          StatGrid(
            cards: [
              StatCard(label: context.tr(WStr.all), value: context.n(mine.length), icon: Icons.history),
              StatCard(label: context.tr(ContentStatus.approved.label), value: context.n(approved), icon: Icons.verified_outlined),
              StatCard(label: context.tr(ContentStatus.changesRequested.label), value: context.n(changes), icon: Icons.change_circle_outlined),
              StatCard(label: context.tr(WStr.waiting), value: context.n(mine.where((i) => i.status == ContentStatus.submitted || i.status == ContentStatus.inReview).length), icon: Icons.hourglass_top),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (mine.isEmpty) EmptyState(icon: Icons.history, title: context.tr(WStr.noHistory)),
          for (final i in mine) _ReviewTile(item: i),
        ],
      ),
    );
  }
}

/// Question creation & editing (TCH-10/11).
class TeacherQuestionsScreen extends ConsumerStatefulWidget {
  const TeacherQuestionsScreen({super.key});

  @override
  ConsumerState<TeacherQuestionsScreen> createState() => _TeacherQuestionsScreenState();
}

class _TeacherQuestionsScreenState extends ConsumerState<TeacherQuestionsScreen> {
  ContentStatus? _status;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(reviewProvider).questions;
    final list = [
      for (final a in all)
        if ((_status == null || a.status == _status) && a.question.stem.matches(_q)) a,
    ];
    return AppPageScaffold(
      title: context.tr(WStr.questions),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tq.new'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QuestionEditorScreen())),
        icon: const Icon(Icons.add),
        label: Text(context.tr(WStr.newQuestion)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DebouncedSearchField(hint: context.tr(WStr.stem), onChanged: (v) => setState(() => _q = v)),
          ChoiceChipBar<ContentStatus?>(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            options: const [null, ContentStatus.draft, ContentStatus.submitted, ContentStatus.inReview, ContentStatus.changesRequested, ContentStatus.approved],
            selected: _status,
            labelOf: (x) => context.tr(x?.label ?? WStr.all),
            onSelected: (x) => setState(() => _status = x),
          ),
          if (list.isEmpty) EmptyState(icon: Icons.edit_note, title: context.tr(WStr.noQuestions)),
          for (final a in list)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                key: Key('tq.${a.question.id}'),
                leading: Icon(a.question.type.icon),
                title: Text(context.tr(a.question.stem), maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${context.tr(a.question.type.label)} · ${_subjectName(context, a.question.subjectId)} · ${context.tr(WStr.version.fill({'n': a.version}))}'),
                trailing: Pill(context.tr(a.status.label), tone: _statusTone(a.status)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => QuestionEditorScreen(existing: a))),
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}

class QuestionEditorScreen extends ConsumerStatefulWidget {
  const QuestionEditorScreen({super.key, this.existing});

  final AuthoredQuestion? existing;

  @override
  ConsumerState<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends ConsumerState<QuestionEditorScreen> {
  static const _types = [QuestionType.mcq, QuestionType.short, QuestionType.creative, QuestionType.numerical, QuestionType.descriptive, QuestionType.trueFalse];
  late final Question? _q = widget.existing?.question;
  late final _stem = TextEditingController(text: _q?.stem.bn ?? '');
  late final _answer = TextEditingController(text: _q?.answer.bn ?? '');
  late final _explanation = TextEditingController(text: _q?.explanation?.bn ?? '');
  late final _options = TextEditingController(text: _q?.options.map((o) => o.bn).join('\n') ?? '');
  late QuestionType _type = _q?.type ?? QuestionType.mcq;
  late Subject _subject = subjectById(_q?.subjectId ?? defaultTeacherSubjectId()) ?? seedSubjects.first;
  late Chapter _chapter = _subject.chapters.where((c) => c.id == _q?.chapterId).firstOrNull ?? _subject.chapters.first;
  late Difficulty _difficulty = _q?.difficulty ?? Difficulty.medium;
  late int _marks = _q?.marks ?? 1;
  late int _correct = _q?.correctIndex ?? 0;
  bool _busy = false;

  bool get _locked => widget.existing != null && !{ContentStatus.draft, ContentStatus.changesRequested}.contains(widget.existing!.status);

  @override
  void dispose() {
    _stem.dispose();
    _answer.dispose();
    _explanation.dispose();
    _options.dispose();
    super.dispose();
  }

  List<String> get _optionLines => [for (final l in _options.text.split('\n')) if (l.trim().isNotEmpty) l.trim()];

  Future<void> _save({required bool submit}) async {
    if (_stem.text.trim().isEmpty || (_type != QuestionType.mcq && _answer.text.trim().isEmpty)) return context.showSnack(WStr.needStem);
    final opts = _optionLines;
    if (_type == QuestionType.mcq && opts.length < 2) return context.showSnack(WStr.needOptions);
    final correct = _correct.clamp(0, opts.isEmpty ? 0 : opts.length - 1);
    final q = Question(
      id: _q?.id ?? 'tq-${DateTime.now().microsecondsSinceEpoch}',
      subjectId: _subject.id,
      chapterId: _chapter.id,
      topicId: _chapter.topics.isEmpty ? _chapter.id : _chapter.topics.first.id,
      type: _type,
      difficulty: _difficulty,
      marks: _type == QuestionType.creative ? 10 : _marks,
      stem: Tr.same(_stem.text.trim()),
      answer: Tr.same(_type == QuestionType.mcq ? opts[correct] : _answer.text.trim()),
      explanation: _explanation.text.trim().isEmpty ? null : Tr.same(_explanation.text.trim()),
      options: _type == QuestionType.mcq ? [for (final o in opts) Tr.same(o)] : const [],
      correctIndex: _type == QuestionType.mcq ? correct : null,
      verified: false,
      createdAt: _q?.createdAt ?? DateTime.now(),
    );
    setState(() => _busy = true);
    try {
      await ref.read(reviewProvider.notifier).saveQuestion(q, submit: submit);
      if (mounted) {
        context.showSnack(submit ? WStr.submitted : WStr.draftSaved);
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = [for (final s in seedSubjects) if (s.level == EducationLevel.ssc) s];
    return AppPageScaffold(
      title: context.tr(widget.existing == null ? WStr.newQuestion : WStr.editQuestion),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.existing != null) ...[
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                Pill(context.tr(widget.existing!.status.label), tone: _statusTone(widget.existing!.status)),
                Pill(context.tr(WStr.version.fill({'n': widget.existing!.version}))),
              ],
            ),
            if (_locked) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: InfoBanner(message: context.tr(WStr.locked), icon: Icons.lock_outline)),
            const SizedBox(height: AppSpacing.md),
          ],
          DropdownButtonFormField<QuestionType>(
            initialValue: _types.contains(_type) ? _type : _types.first,
            decoration: InputDecoration(labelText: context.tr(WStr.type)),
            items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(context.tr(t.label)))],
            onChanged: _locked ? null : (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<Subject>(
            isExpanded: true,
            initialValue: subjects.contains(_subject) ? _subject : subjects.first,
            decoration: InputDecoration(labelText: context.tr(WStr.subject)),
            items: [for (final s in subjects) DropdownMenuItem(value: s, child: Text(context.tr(s.name)))],
            onChanged: _locked
                ? null
                : (v) => setState(() {
                    _subject = v ?? _subject;
                    _chapter = _subject.chapters.first;
                  }),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<Chapter>(
            key: ValueKey(_subject.id),
            isExpanded: true,
            initialValue: _chapter,
            decoration: InputDecoration(labelText: context.tr(WStr.chapter)),
            items: [for (final c in _subject.chapters) DropdownMenuItem(value: c, child: Text(context.tr(c.title), overflow: TextOverflow.ellipsis))],
            onChanged: _locked ? null : (v) => setState(() => _chapter = v ?? _chapter),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(key: const Key('tq.stem'), controller: _stem, enabled: !_locked, maxLines: 3, decoration: InputDecoration(labelText: context.tr(WStr.stem))),
          const SizedBox(height: AppSpacing.sm),
          if (_type == QuestionType.mcq) ...[
            TextField(key: const Key('tq.options'), controller: _options, enabled: !_locked, maxLines: 4, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr(WStr.options))),
            const SizedBox(height: AppSpacing.sm),
            if (_optionLines.length >= 2)
              DropdownButtonFormField<int>(
                initialValue: _correct.clamp(0, _optionLines.length - 1),
                decoration: InputDecoration(labelText: context.tr(WStr.correct)),
                items: [for (final (i, o) in _optionLines.indexed) DropdownMenuItem(value: i, child: Text(o, overflow: TextOverflow.ellipsis))],
                onChanged: _locked ? null : (v) => setState(() => _correct = v ?? 0),
              ),
          ] else
            TextField(key: const Key('tq.answer'), controller: _answer, enabled: !_locked, maxLines: 3, decoration: InputDecoration(labelText: context.tr(WStr.answer))),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: _explanation, enabled: !_locked, maxLines: 3, decoration: InputDecoration(labelText: context.tr(WStr.explanation))),
          const SizedBox(height: AppSpacing.sm),
          Text(context.tr(WStr.difficulty), style: context.text.labelMedium),
          SegmentedButton<Difficulty>(
            segments: [for (final d in Difficulty.values) ButtonSegment(value: d, label: Text(context.tr(d.label)))],
            selected: {_difficulty},
            onSelectionChanged: _locked ? null : (v) => setState(() => _difficulty = v.first),
          ),
          if (_type != QuestionType.creative) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('${context.tr(WStr.marks)}: ${context.n(_marks)}'),
                Expanded(child: Slider(value: _marks.toDouble(), min: 1, max: 10, divisions: 9, onChanged: _locked ? null : (v) => setState(() => _marks = v.round()))),
              ],
            ),
          ],
          if (widget.existing != null && widget.existing!.versions.isNotEmpty) ...[
            SectionHeader(title: context.tr(WStr.history)),
            for (final (at, summary) in widget.existing!.versions.reversed) Text('• $summary · ${relativeTime(at, context.lang)}', style: context.text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: OutlinedButton(key: const Key('tq.draft'), onPressed: _busy || _locked ? null : () => _save(submit: false), child: Text(context.tr(WStr.saveDraft)))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: FilledButton(key: const Key('tq.submit'), onPressed: _busy || _locked ? null : () => _save(submit: true), child: Text(context.tr(WStr.submitReview)))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rubric management (TCH-06).
class TeacherRubricsScreen extends ConsumerWidget {
  const TeacherRubricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rubrics = ref.watch(reviewProvider).rubrics;
    return AppPageScaffold(
      title: context.tr(WStr.rubrics),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('rubric.new'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RubricEditorScreen())),
        icon: const Icon(Icons.add),
        label: Text(context.tr(WStr.newRubric)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rubrics)
            Card(
              key: Key('rubric.${r.id}'),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(r.name, style: context.text.titleSmall)),
                        Pill(context.tr(r.status.label), tone: _statusTone(r.status)),
                      ],
                    ),
                    Text('${r.subjectId == null ? context.tr(WStr.allSubjects) : _subjectName(context, r.subjectId!)} · ${context.tr(r.use.label)} · ${r.owner}', style: context.text.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    for (final c in r.criteria)
                      Row(
                        children: [
                          Expanded(child: Text('• ${c.criterion}${c.description.isEmpty ? '' : ' — ${c.description}'}', style: context.text.bodySmall)),
                          Text(context.n(_fmt(c.marks)), style: context.text.labelMedium),
                        ],
                      ),
                    const Divider(),
                    Row(
                      children: [
                        Text('${context.tr(WStr.total)}: ${context.n(_fmt(r.total))}', style: context.text.labelLarge),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RubricEditorScreen(existing: r))),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(context.tr(WStr.editRubric)),
                        ),
                        IconButton(
                          tooltip: context.tr(S.delete),
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await showConfirmDialog(context, title: S.delete, destructive: true, confirmLabel: S.delete)) return;
                            await ref.read(reviewProvider.notifier).removeRubric(r.id);
                            if (context.mounted) context.showSnack(S.deleted);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

class RubricEditorScreen extends ConsumerStatefulWidget {
  const RubricEditorScreen({super.key, this.existing});

  final Rubric? existing;

  @override
  ConsumerState<RubricEditorScreen> createState() => _RubricEditorScreenState();
}

class _RubricEditorScreenState extends ConsumerState<RubricEditorScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late RubricUse _use = widget.existing?.use ?? RubricUse.creative;
  late String? _subjectId = widget.existing?.subjectId;
  late final List<(TextEditingController, TextEditingController, double)> _rows = [
    for (final c in widget.existing?.criteria ?? const [RubricCriterion('', 1, '')]) (TextEditingController(text: c.criterion), TextEditingController(text: c.description), c.marks),
  ];

  @override
  void dispose() {
    _name.dispose();
    for (final (a, b, _) in _rows) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  double get _total => _rows.fold(0, (s, r) => s + r.$3);

  Future<void> _save() async {
    final r = Rubric(
      id: widget.existing?.id ?? 'rb-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      use: _use,
      subjectId: _subjectId,
      criteria: [for (final (a, b, m) in _rows) if (a.text.trim().isNotEmpty) RubricCriterion(a.text.trim(), m, b.text.trim())],
      status: widget.existing?.status ?? ContentStatus.draft,
      owner: widget.existing?.owner ?? teacherActor.name,
    );
    try {
      await ref.read(reviewProvider.notifier).saveRubric(r);
      if (mounted) {
        context.showSnack(WStr.rubricSaved);
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) context.showErrorSnack(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = [for (final s in seedSubjects) if (s.level == EducationLevel.ssc) s];
    return AppPageScaffold(
      title: context.tr(widget.existing == null ? WStr.newRubric : WStr.editRubric),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(key: const Key('rubric.name'), controller: _name, decoration: InputDecoration(labelText: context.tr(WStr.rubricName))),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<RubricUse>(
            initialValue: _use,
            decoration: InputDecoration(labelText: context.tr(WStr.appliesTo)),
            items: [for (final u in RubricUse.values) DropdownMenuItem(value: u, child: Text(context.tr(u.label)))],
            onChanged: (v) => setState(() => _use = v ?? _use),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _subjectId,
            decoration: InputDecoration(labelText: context.tr(WStr.subject)),
            items: [
              DropdownMenuItem(child: Text(context.tr(WStr.allSubjects))),
              for (final s in subjects) DropdownMenuItem(value: s.id, child: Text(context.tr(s.name))),
            ],
            onChanged: (v) => setState(() => _subjectId = v),
          ),
          SectionHeader(title: context.tr(WStr.criterion)),
          for (final (i, (a, b, m)) in _rows.indexed)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(key: Key('rubric.c$i'), controller: a, decoration: InputDecoration(labelText: context.tr(WStr.criterion)))),
                        IconButton(
                          tooltip: context.tr(S.delete),
                          onPressed: _rows.length == 1
                              ? null
                              : () => setState(() {
                                  final r = _rows.removeAt(i);
                                  r.$1.dispose();
                                  r.$2.dispose();
                                }),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    TextField(controller: b, decoration: InputDecoration(labelText: context.tr(WStr.description))),
                    Row(
                      children: [
                        Text('${context.tr(WStr.marks)}: ${context.n(_fmt(m))}'),
                        Expanded(child: Slider(value: m, min: 0.5, max: 10, divisions: 19, onChanged: (v) => setState(() => _rows[i] = (a, b, v)))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            key: const Key('rubric.addCriterion'),
            onPressed: () => setState(() => _rows.add((TextEditingController(), TextEditingController(), 1))),
            icon: const Icon(Icons.add),
            label: Text(context.tr(WStr.criterion)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${context.tr(WStr.total)}: ${context.n(_fmt(_total))}', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          FilledButton(key: const Key('rubric.save'), onPressed: _save, child: Text(context.tr(S.save))),
        ],
      ),
    );
  }
}

/// Assigned subjects (TCH-02) with chapters, bank size, classes and open reviews.
class TeacherSubjectsScreen extends ConsumerWidget {
  const TeacherSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = {for (final c in teacherClasses) c.subjectId};
    final bank = ref.watch(questionRepositoryProvider).cached;
    final reviews = ref.watch(reviewProvider).items;
    return AppPageScaffold(
      title: context.tr(WStr.subjects),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final id in ids)
            if (subjectById(id) case final s?)
              Card(
                key: Key('subject.$id'),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconTile(icon: s.icon, color: s.color),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Text(context.tr(s.name), style: context.text.titleMedium)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      KeyValueRow(context.tr(WStr.chapters), context.n(s.chapters.length)),
                      KeyValueRow(context.tr(WStr.bankQuestions), context.n(bank.where((q) => q.subjectId == id).length)),
                      KeyValueRow(context.tr(WStr.classes), teacherClasses.where((c) => c.subjectId == id).map((c) => c.name).join(', ')),
                      KeyValueRow(context.tr(WStr.openReviews), context.n(reviews.where((r) => r.subjectId == id && r.status.index < ContentStatus.approved.index).length)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [for (final c in s.chapters) Pill('${context.n(c.number)}. ${context.tr(c.title)}')],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Student performance across classes (TCH-18) with per-student detail and feedback.
class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  String _q = '';
  bool _helpOnly = false;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final c in teacherClasses)
        for (final st in c.students)
          if (st.contains(_q.trim()) && (!_helpOnly || c.masteryOf(st) < 55)) (c, st, c.masteryOf(st)),
    ]..sort((a, b) => a.$3.compareTo(b.$3));
    return AppPageScaffold(
      title: context.tr(WStr.students),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(WStr.studentsSub), style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          DebouncedSearchField(hint: context.tr(WStr.searchStudents), onChanged: (v) => setState(() => _q = v)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChip(key: const Key('students.help'), label: Text(context.tr(WStr.needsHelp)), selected: _helpOnly, onSelected: (v) => setState(() => _helpOnly = v)),
          ),
          for (final (c, st, m) in rows)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                key: Key('student.$st'),
                leading: ProgressRing(value: m / 100, size: 40),
                title: Text(st),
                subtitle: Text(c.name),
                trailing: m < 55 ? Pill(context.tr(WStr.needsHelp), tone: Tone.warning) : Pill(context.tr(WStr.onTrack), tone: Tone.success),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TeacherStudentDetailScreen(cls: c, student: st))),
              ),
            ),
        ],
      ),
    );
  }
}

class TeacherStudentDetailScreen extends ConsumerWidget {
  const TeacherStudentDetailScreen({super.key, required this.cls, required this.student});

  final TeacherClass cls;
  final String student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(teacherProvider);
    final subs = [for (final s in t.submissions) if (s.student == student) s];
    final work = [
      for (final a in t.assignments)
        if (a.classId == cls.id)
          for (final w in a.work())
            if (w.student == student) (a, w),
    ];
    final subject = subjectById(cls.subjectId);
    return AppPageScaffold(
      title: student,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(cls.name, style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          LabeledProgress(label: context.tr(WStr.mastery), value: cls.masteryOf(student) / 100),
          if (subject != null) ...[
            SectionHeader(title: context.tr(WStr.chapters)),
            for (final ch in subject.chapters.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: LabeledProgress(label: context.tr(ch.title), value: (cls.masteryOf('$student${ch.id}') - 20).clamp(0, 100) / 100, dense: true),
              ),
          ],
          SectionHeader(title: context.tr(WStr.work)),
          if (subs.isEmpty && work.isEmpty) Text('—', style: context.text.bodySmall),
          for (final s in subs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(s.title),
              subtitle: Text(context.tr(s.stage.label)),
              trailing: Text(s.reviewed ? '${context.n(_fmt(s.finalMarks!))}/${context.n(s.total)}' : '~${context.n(_fmt(s.aiMarks))}'),
            ),
          for (final (a, w) in work)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(w.status == WorkStatus.missing ? Icons.cancel_outlined : Icons.assignment_turned_in_outlined),
              title: Text(a.title),
              subtitle: Text(context.tr(switch (w.status) {
                WorkStatus.submitted => WStr.submittedLabel,
                WorkStatus.late => WStr.lateLabel,
                WorkStatus.missing => WStr.missingLabel,
              })),
              trailing: w.grade == null ? null : Text('${context.n(_fmt(w.grade!))}/${context.n(a.total)}'),
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('student.feedback'),
            onPressed: () async {
              final text = await showTextInputDialog(context, title: WStr.sendFeedback, label: WStr.feedback, maxLines: 3);
              if (text == null || text.trim().isEmpty) return;
              await ref.read(teacherProvider.notifier).sendStudentFeedback(student, text.trim());
              if (context.mounted) context.showSnack(WStr.feedbackSent);
            },
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(context.tr(WStr.sendFeedback)),
          ),
        ],
      ),
    );
  }
}

/// Submissions for one assignment (TCH-15): who submitted, late or missing; grade + feedback.
class TeacherSubmissionsScreen extends ConsumerWidget {
  const TeacherSubmissionsScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(teacherProvider).assignments.where((x) => x.id == assignmentId).firstOrNull;
    if (a == null) return AppPageScaffold(title: context.tr(WStr.submissions), body: EmptyState(title: context.tr(S.notFound), icon: Icons.search_off));
    final work = a.work();
    final missing = work.where((w) => w.status == WorkStatus.missing).length;
    return AppPageScaffold(
      title: context.tr(WStr.submissions),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(a.title, style: context.text.titleMedium),
          Text(teacherClasses.firstWhere((c) => c.id == a.classId).name, style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          StatGrid(
            cards: [
              StatCard(label: context.tr(WStr.submittedLabel), value: context.n(work.length - missing), icon: Icons.assignment_turned_in_outlined),
              StatCard(label: context.tr(WStr.missingLabel), value: context.n(missing), icon: Icons.assignment_late_outlined),
            ],
          ),
          if (missing > 0)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(onPressed: () => context.showSnack(WStr.reminded), icon: const Icon(Icons.notifications_active_outlined), label: Text(context.tr(WStr.remind))),
            ),
          for (final w in work)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                key: Key('work.${w.student}'),
                leading: CircleAvatar(child: Text(w.student.characters.first)),
                title: Text(w.student),
                subtitle: Text([
                  context.tr(switch (w.status) {
                    WorkStatus.submitted => WStr.submittedLabel,
                    WorkStatus.late => WStr.lateLabel,
                    WorkStatus.missing => WStr.missingLabel,
                  }),
                  if (w.at != null) relativeTime(w.at!, context.lang),
                  if (w.feedback != null && w.feedback!.isNotEmpty) w.feedback!,
                ].join(' · ')),
                trailing: w.status == WorkStatus.missing
                    ? null
                    : w.grade != null
                        ? Pill('${context.n(_fmt(w.grade!))}/${context.n(a.total)}', tone: Tone.success)
                        : TextButton(key: Key('grade.${w.student}'), onPressed: () => _grade(context, ref, a, w), child: Text(context.tr(WStr.grade))),
                onTap: w.status == WorkStatus.missing ? null : () => _grade(context, ref, a, w),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _grade(BuildContext context, WidgetRef ref, Assignment a, StudentWork w) async {
    final result = await showModalBottomSheet<(double, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GradeSheet(title: '${w.student} · ${a.title}', total: a.total, initial: w.grade ?? a.total * 0.7, note: w.feedback ?? ''),
    );
    if (result == null) return;
    await ref.read(teacherProvider.notifier).gradeWork(a.id, w.student, result.$1, result.$2);
    if (context.mounted) context.showSnack(WStr.graded);
  }
}

class _GradeSheet extends StatefulWidget {
  const _GradeSheet({required this.title, required this.total, required this.initial, required this.note});

  final String title;
  final int total;
  final double initial;
  final String note;

  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<_GradeSheet> {
  late double _marks = (widget.initial * 2).round() / 2;
  late final _note = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('${context.tr(WStr.marks)}: ${context.n(_fmt(_marks))}/${context.n(widget.total)}'),
        Slider(key: const Key('grade.marks'), value: _marks, max: widget.total.toDouble(), divisions: widget.total * 2, onChanged: (v) => setState(() => _marks = v)),
        TextField(key: const Key('grade.note'), controller: _note, maxLines: 3, decoration: InputDecoration(labelText: context.tr(WStr.feedback))),
        const SizedBox(height: AppSpacing.md),
        FilledButton(key: const Key('grade.save'), onPressed: () => Navigator.pop(context, (_marks, _note.text.trim())), child: Text(context.tr(S.save))),
      ],
    ),
  );
}
