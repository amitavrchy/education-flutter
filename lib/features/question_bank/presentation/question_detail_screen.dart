import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../../shared/widgets/section_header.dart';
import '../../curriculum/data/curriculum_repository.dart';
import '../../notes/application/notes_controller.dart';
import '../application/practice_controller.dart';
import '../data/question_repository.dart';
import '../domain/question.dart';
import '../question_strings.dart';
import 'widgets/question_widgets.dart';

final questionProvider = FutureProvider.autoDispose.family<Question, String>(
  (ref, id) => ref.watch(questionRepositoryProvider).question(id),
);

final relatedQuestionsProvider = FutureProvider.autoDispose.family<List<Question>, String>((ref, id) async {
  final q = await ref.watch(questionProvider(id).future);
  return ref.watch(questionRepositoryProvider).related(q);
});

/// One question with answer reveal, self-marking, bookmark, sets, report, copy, print view
/// and related questions.
class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(questionProvider(questionId));
    final bookmarked = ref.watch(practiceProvider.select((s) => s.isBookmarked(questionId)));
    final q = value.value;
    return AppPageScaffold(
      title: context.tr(S.questions),
      showShortcuts: false,
      actions: [
        if (q != null) ...[
          IconButton(
            key: const Key('question.bookmark'),
            tooltip: context.tr(bookmarked ? S.removeBookmark : S.bookmark),
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () async {
              final added = await ref.read(practiceProvider.notifier).toggleBookmark(q.id);
              if (context.mounted) context.showSnack(added ? S.bookmarked : S.removeBookmark);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, ref, q, v),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'set', child: ListTile(leading: const Icon(Icons.playlist_add), title: Text(context.tr(QStrings.addToSet)))),
              PopupMenuItem(value: 'note', child: ListTile(leading: const Icon(Icons.note_add_outlined), title: Text(context.tr(QStrings.saveToNotes)))),
              PopupMenuItem(value: 'copy', child: ListTile(leading: const Icon(Icons.copy), title: Text(context.tr(S.copy)))),
              PopupMenuItem(value: 'print', child: ListTile(leading: const Icon(Icons.print_outlined), title: Text(context.tr(QStrings.printView)))),
              PopupMenuItem(value: 'report', child: ListTile(leading: const Icon(Icons.flag_outlined), title: Text(context.tr(S.report)))),
            ],
          ),
        ],
      ],
      body: AsyncValueView<Question>(
        value: value,
        onRetry: () => ref.invalidate(questionProvider(questionId)),
        data: (q) => _QuestionBody(question: q),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, Question q, String action) async {
    switch (action) {
      case 'set':
        await showAddToSetSheet(context, ref, q.id);
      case 'note':
        final note = await ref.read(notesProvider.notifier).generateFromQuestion(q, context.lang);
        if (context.mounted) await context.push(AppRoutes.note(note.id));
      case 'copy':
        final lang = context.lang;
        final text = [
          plainTextOf(q.stem.of(lang)),
          for (var i = 0; i < q.options.length; i++) '${optionLabel(context, i)}. ${plainTextOf(q.options[i].of(lang))}',
        ].join('\n');
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) context.showSnack(S.copied);
      case 'print':
        await Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => _PrintView(question: q)));
      case 'report':
        final reason = await showReportDialog(context, reasons: QStrings.reportReasons);
        if (reason == null) return;
        try {
          await ref.read(questionRepositoryProvider).report(q.id, reason);
          if (context.mounted) context.showSnack(S.reportSent);
        } catch (e) {
          if (context.mounted) context.showErrorSnack(e);
        }
    }
  }
}

/// Bottom sheet listing practice sets plus "new set".
Future<void> showAddToSetSheet(BuildContext context, WidgetRef ref, String questionId) async {
  final sets = ref.read(practiceProvider).sets;
  final picked = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(leading: const Icon(Icons.add), title: Text(context.tr(QStrings.newSet)), onTap: () => Navigator.pop(context, '')),
        for (final s in sets)
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(s.name),
            subtitle: Text(context.tr(QStrings.setQuestions.fill({'n': s.questionIds.length}))),
            onTap: () => Navigator.pop(context, s.id),
          ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;
  final controller = ref.read(practiceProvider.notifier);
  if (picked.isEmpty) {
    final name = await showTextInputDialog(context, title: QStrings.newSet, label: QStrings.setName);
    if (name == null) return;
    await controller.createSet(name, questionIds: [questionId]);
  } else {
    await controller.addToSet(picked, questionId);
  }
  if (context.mounted) context.showSnack(QStrings.addedToSet);
}

class _QuestionBody extends ConsumerStatefulWidget {
  const _QuestionBody({required this.question});

  final Question question;

  @override
  ConsumerState<_QuestionBody> createState() => _QuestionBodyState();
}

class _QuestionBodyState extends ConsumerState<_QuestionBody> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final where = ref.read(curriculumRepositoryProvider).findTopic(q.topicId);
    final attempts = ref.watch(practiceProvider.select((s) => s.attemptsFor(q.id)));
    final related = ref.watch(relatedQuestionsProvider(q.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (where != null)
          InkWell(
            onTap: () => context.push(AppRoutes.topic(where.topic.id)),
            child: Text(
              '${context.tr(where.subject.name)} › ${context.tr(where.chapter.title)} › ${context.tr(where.topic.title)}',
              style: context.text.labelMedium?.copyWith(color: where.subject.color),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        QuestionMetaRow(question: q),
        if (q.frequency > 0 || attempts > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (q.frequency > 0) context.tr(QStrings.frequency.fill({'n': q.frequency})),
              if (attempts > 0) context.tr(QStrings.attemptedTimes.fill({'n': attempts})),
            ].join(' · '),
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: QuestionPrompt(question: q))),
        const SizedBox(height: AppSpacing.md),
        if (_revealed) ...[
          AnswerPanel(question: q),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('question.wrong'),
                  style: OutlinedButton.styleFrom(foregroundColor: context.palette.danger),
                  onPressed: () => _mark(false),
                  icon: const Icon(Icons.close),
                  label: Text(context.tr(QStrings.iMissed)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('question.right'),
                  style: FilledButton.styleFrom(backgroundColor: context.palette.success),
                  onPressed: () => _mark(true),
                  icon: const Icon(Icons.check),
                  label: Text(context.tr(QStrings.iGotIt)),
                ),
              ),
            ],
          ),
        ],
        TextButton.icon(
          key: const Key('question.reveal'),
          onPressed: () => setState(() => _revealed = !_revealed),
          icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          label: Text(context.tr(_revealed ? QStrings.hideAnswer : QStrings.showAnswer)),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.tutor(
            subjectId: q.subjectId,
            chapterId: q.chapterId,
            topicId: q.topicId,
            prompt: plainTextOf(q.stem.of(context.lang)),
          )),
          icon: const Icon(Icons.smart_toy_outlined),
          label: Text(context.tr(S.askAi)),
        ),
        SectionHeader(title: context.tr(QStrings.related)),
        AsyncValueView<List<Question>>(
          value: related,
          compactError: true,
          data: (list) => Column(
            children: [
              for (final r in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: QuestionListTile(question: r, onTap: () => context.pushReplacement(AppRoutes.question(r.id))),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Future<void> _mark(bool correct) async {
    await ref.read(practiceProvider.notifier).recordAttempt(widget.question, correct: correct);
    if (mounted) context.showSnack(correct ? QStrings.markedCorrect : QStrings.markedWrong);
  }
}

/// Clean black-on-white layout for printing or saving.
class _PrintView extends StatelessWidget {
  const _PrintView({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(brightness: Brightness.light, colorSchemeSeed: Colors.grey, useMaterial3: true),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: Text(context.tr(QStrings.printView))),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(context.tr(QStrings.printNote), style: context.text.bodySmall),
              const Divider(height: AppSpacing.xxl),
              QuestionPrompt(question: question),
              const SizedBox(height: AppSpacing.xl),
              AnswerPanel(question: question),
            ],
          ),
        ),
      ),
    );
  }
}
