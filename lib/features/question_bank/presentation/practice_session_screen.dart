import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/progress.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../application/practice_controller.dart';
import '../domain/question.dart';
import '../question_strings.dart';
import 'widgets/question_widgets.dart';

/// Focused one-question-at-a-time practice. Objective questions are checked instantly;
/// written ones reveal the model answer and the student self-marks. Every answer updates
/// topic mastery; finishing logs the session (minutes + XP).
class PracticeSessionScreen extends ConsumerWidget {
  const PracticeSessionScreen({super.key, required this.request});

  final PracticeRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(practiceSessionProvider(request));
    return AsyncValueView<List<Question>>(
      value: value,
      onRetry: () => ref.invalidate(practiceSessionProvider(request)),
      loading: Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      data: (questions) => questions.isEmpty
          ? Scaffold(
              appBar: AppBar(title: Text(context.tr(QStrings.session))),
              body: EmptyState(
                icon: Icons.quiz_outlined,
                title: context.tr(QStrings.noQuestions),
                message: context.tr(QStrings.noQuestionsHint),
                action: FilledButton(
                  onPressed: () => context.pushReplacement(AppRoutes.practiceSession(mode: 'mixed')),
                  child: Text(context.tr(const Tr('মিশ্র অনুশীলন', 'Mixed practice'))),
                ),
              ),
            )
          : _Session(questions: questions, request: request),
    );
  }
}

class _Session extends ConsumerStatefulWidget {
  const _Session({required this.questions, required this.request});

  final List<Question> questions;
  final PracticeRequest request;

  @override
  ConsumerState<_Session> createState() => _SessionState();
}

class _SessionState extends ConsumerState<_Session> {
  final DateTime _started = DateTime.now();
  final Map<int, bool> _results = {};
  int _index = 0;
  int? _selected;
  bool _revealed = false;
  bool _finished = false;
  final _text = TextEditingController();

  Question get _q => widget.questions[_index];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _record(bool correct) async {
    if (_results.containsKey(_index)) return;
    setState(() {
      _results[_index] = correct;
      _revealed = true;
    });
    await ref.read(practiceProvider.notifier).recordAttempt(_q, correct: correct);
  }

  void _check() {
    if (_q.type == QuestionType.fillBlank) {
      _record(_q.isAcceptedText(_text.text));
    } else if (_selected != null) {
      _record(_q.isCorrectChoice(_selected!));
    }
  }

  Future<void> _next() async {
    if (_index < widget.questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
        _text.clear();
      });
      return;
    }
    final minutes = DateTime.now().difference(_started).inMinutes.clamp(1, 120);
    final correct = _results.values.where((c) => c).length;
    await ref
        .read(learningProgressProvider.notifier)
        .logActivity(ActivityKind.practice, minutes: minutes, xp: 5 + correct * 5, subjectId: widget.request.subjectId ?? _q.subjectId);
    setState(() => _finished = true);
  }

  Future<bool> _confirmExit() async {
    if (_finished || _results.isEmpty) return true;
    return showConfirmDialog(context, title: QStrings.exitSession, message: QStrings.exitSessionBody, confirmLabel: QStrings.leave);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _Summary(questions: widget.questions, results: _results);
    final total = widget.questions.length;
    final answered = _results.containsKey(_index);
    return PopScope(
      canPop: _results.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr(QStrings.questionNofM.fill({'n': _index + 1, 'm': total}))),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (_index + (answered ? 1 : 0)) / total),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: ListView(
                padding: AppSpacing.screen,
                children: [
                  QuestionMetaRow(question: _q, showSource: false),
                  const SizedBox(height: AppSpacing.md),
                  QuestionPrompt(question: _q, showOptions: false),
                  const SizedBox(height: AppSpacing.lg),
                  ..._answerArea(context, answered),
                  if (_revealed) ...[
                    const SizedBox(height: AppSpacing.md),
                    if (answered) _Verdict(correct: _results[_index]!),
                    const SizedBox(height: AppSpacing.sm),
                    AnswerPanel(question: _q),
                  ],
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: _primaryButton(context, answered)),
        ),
      ),
    );
  }

  List<Widget> _answerArea(BuildContext context, bool answered) {
    final q = _q;
    if (q.type == QuestionType.mcq || q.type == QuestionType.trueFalse) {
      return [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OptionTile(
              key: Key('option.$i'),
              label: optionLabel(context, i),
              text: context.tr(q.options[i]),
              selected: _selected == i,
              state: !answered
                  ? null
                  : q.isCorrectChoice(i)
                  ? true
                  : (_selected == i ? false : null),
              onTap: answered ? null : () => setState(() => _selected = i),
            ),
          ),
      ];
    }
    if (q.type == QuestionType.fillBlank) {
      return [
        TextField(
          key: const Key('practice.text'),
          controller: _text,
          enabled: !answered,
          decoration: InputDecoration(labelText: context.tr(QStrings.typeAnswer)),
          onSubmitted: (_) => _check(),
          onChanged: (_) => setState(() {}),
        ),
      ];
    }
    return const [];
  }

  Widget _primaryButton(BuildContext context, bool answered) {
    final q = _q;
    final last = _index == widget.questions.length - 1;
    if (answered) {
      return FilledButton(key: const Key('practice.next'), onPressed: _next, child: Text(context.tr(last ? QStrings.finish : S.next)));
    }
    if (q.type.isObjective) {
      final ready = q.type == QuestionType.fillBlank ? _text.text.trim().isNotEmpty : _selected != null;
      return FilledButton(key: const Key('practice.check'), onPressed: ready ? _check : null, child: Text(context.tr(QStrings.check)));
    }
    if (!_revealed) {
      return FilledButton.tonal(
        key: const Key('practice.reveal'),
        onPressed: () => setState(() => _revealed = true),
        child: Text(context.tr(QStrings.showAnswer)),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(key: const Key('practice.selfWrong'), onPressed: () => _record(false), child: Text(context.tr(QStrings.iMissed))),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton(key: const Key('practice.selfRight'), onPressed: () => _record(true), child: Text(context.tr(QStrings.iGotIt))),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({super.key, required this.label, required this.text, required this.selected, required this.state, this.onTap});

  final String label;
  final String text;
  final bool selected;

  /// true = correct answer, false = chosen wrong answer, null = neutral.
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final border = switch (state) {
      true => p.success,
      false => p.danger,
      null => selected ? context.colors.primary : context.colors.outlineVariant,
    };
    final fill = switch (state) {
      true => p.successContainer,
      false => p.dangerContainer,
      null => selected ? context.colors.primaryContainer.withValues(alpha: 0.5) : null,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '$label. $text',
      child: Material(
        color: fill ?? context.colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.field,
          side: BorderSide(color: border, width: selected || state != null ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: AppRadius.field,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: border.withValues(alpha: 0.15),
                  child: Text(label, style: TextStyle(color: border)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: InlineRich(text, style: context.text.bodyLarge!)),
                if (state == true) Icon(Icons.check_circle, color: p.success),
                if (state == false) Icon(Icons.cancel, color: p.danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    final color = correct ? context.palette.success : context.palette.danger;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(correct ? Icons.celebration_outlined : Icons.info_outline, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(context.tr(correct ? QStrings.correct : QStrings.incorrect), style: context.text.titleMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.questions, required this.results});

  final List<Question> questions;
  final Map<int, bool> results;

  @override
  Widget build(BuildContext context) {
    final correct = results.values.where((c) => c).length;
    final total = questions.length;
    final wrongIds = [
      for (final e in results.entries)
        if (!e.value) questions[e.key].id,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(QStrings.sessionDone)), automaticallyImplyLeading: false),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ProgressRing(
              value: total == 0 ? 0 : correct / total,
              size: 120,
              stroke: 10,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.pct(total == 0 ? 0 : correct / total * 100), style: context.text.headlineMedium),
                  Text(context.tr(QStrings.scoreLine.fill({'c': correct, 't': total})), style: context.text.labelMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(context.tr(QStrings.xpEarned.fill({'n': 5 + correct * 5})), style: context.text.titleMedium?.copyWith(color: context.palette.xp)),
          ),
          Center(child: Text(context.tr(QStrings.masteryUpdated), style: context.text.bodySmall)),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < questions.length; i++)
            QuestionListTile(question: questions[i], status: results[i], onTap: () => context.push(AppRoutes.question(questions[i].id))),
          const SizedBox(height: AppSpacing.lg),
          if (wrongIds.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => context.pushReplacement(AppRoutes.practiceSession(mode: 'wrong')),
              icon: const Icon(Icons.replay),
              label: Text(context.tr(QStrings.reviewWrong)),
            ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(key: const Key('practice.done'), onPressed: () => context.pop(), child: Text(context.tr(S.done))),
        ],
      ),
    );
  }
}
