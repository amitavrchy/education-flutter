import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/common_strings.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/time_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/rich_content.dart';
import '../../question_bank/data/question_repository.dart';
import '../../question_bank/domain/question.dart';
import '../../question_bank/presentation/widgets/question_widgets.dart';
import '../application/exam_controller.dart';
import '../domain/exam.dart';
import '../exam_strings.dart';

/// Full-screen exam: instructions, timer with autosave, palette, review flags, written and
/// handwritten answers, submit confirmation, time-up auto-submit and session recovery.
class ExamTakeScreen extends ConsumerWidget {
  const ExamTakeScreen({super.key, required this.attemptId});

  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempt = ref.watch(examProvider.select((s) => s.attempt(attemptId)));
    if (attempt == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off, title: context.tr(S.notFound)));
    }
    if (attempt.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pushReplacement(AppRoutes.examResult(attemptId));
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _ExamRunner(key: ValueKey(attemptId), initial: attempt);
  }
}

class _ExamRunner extends ConsumerStatefulWidget {
  const _ExamRunner({super.key, required this.initial});

  final ExamAttempt initial;

  @override
  ConsumerState<_ExamRunner> createState() => _ExamRunnerState();
}

class _ExamRunnerState extends ConsumerState<_ExamRunner> {
  late int _remaining = widget.initial.remainingSeconds ?? widget.initial.config.timeLimitMinutes * 60;
  late bool _started = _isRecovered;
  Timer? _timer;
  Timer? _textDebounce;
  final _text = TextEditingController();
  bool _submitting = false;

  bool get _isRecovered =>
      widget.initial.answers.isNotEmpty || (widget.initial.remainingSeconds ?? 0) < widget.initial.config.timeLimitMinutes * 60;

  ExamController get _ctl => ref.read(examProvider.notifier);

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _text.text = a.answerFor(a.questionIds[a.currentIndex]).text ?? '';
    if (_started) {
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.showSnack(ExamStrings.recovered);
      });
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textDebounce?.cancel();
    _text.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining % 5 == 0) _ctl.saveRemaining(widget.initial.id, _remaining);
      if (_remaining <= 0) {
        t.cancel();
        _submit(expired: true);
      }
    });
  }

  Future<void> _submit({bool expired = false}) async {
    if (_submitting) return;
    _submitting = true;
    _timer?.cancel();
    await _ctl.saveRemaining(widget.initial.id, _remaining.clamp(0, 1 << 30));
    await _ctl.submit(widget.initial.id, expired: expired);
    if (!mounted) return;
    if (expired) context.showSnack(ExamStrings.timeUp);
    context.pushReplacement(AppRoutes.examResult(widget.initial.id));
  }

  Future<void> _confirmSubmit(ExamAttempt a) async {
    final ok = await showConfirmDialog(
      context,
      title: ExamStrings.submitConfirm,
      message: ExamStrings.submitSummary.fill({
        'a': a.answeredCount,
        'u': a.questionIds.length - a.answeredCount,
        'r': a.reviewCount,
      }),
      confirmLabel: ExamStrings.submit,
    );
    if (ok) await _submit();
  }

  void _goTo(ExamAttempt a, int index) {
    if (index < 0 || index >= a.questionIds.length) return;
    _textDebounce?.cancel();
    _ctl.goTo(a.id, index);
    final next = a.answerFor(a.questionIds[index]);
    _text.text = next.text ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(examProvider.select((s) => s.attempt(widget.initial.id))) ?? widget.initial;
    final questions = {for (final q in ref.watch(questionRepositoryProvider).cached) q.id: q};
    if (!_started) {
      return _Instructions(
        attempt: a,
        onBegin: () => setState(() {
          _started = true;
          _startTimer();
        }),
      );
    }

    final qid = a.questionIds[a.currentIndex];
    final q = questions[qid];
    final ans = a.answerFor(qid);
    final low = _remaining <= 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showConfirmDialog(context, title: ExamStrings.leaveExam, message: ExamStrings.leaveExamBody, confirmLabel: ExamStrings.leave);
        if (leave && context.mounted) {
          _timer?.cancel();
          await _ctl.saveRemaining(a.id, _remaining);
          if (context.mounted) context.pop();
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _goTo(a, a.currentIndex + 1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _goTo(a, a.currentIndex - 1),
          for (var i = 0; i < 4; i++)
            SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () {
              if (q != null && i < q.options.length) _ctl.answer(a.id, qid, ans.copyWith(choice: () => i));
            },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(context.tr(a.title), maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                Semantics(
                  label: context.tr(ExamStrings.timeLeft),
                  value: clockLabel(Duration(seconds: _remaining.clamp(0, 1 << 30)), context.lang),
                  liveRegion: low,
                  child: Container(
                    key: const Key('exam.timer'),
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: low ? context.palette.dangerContainer : context.colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 18, color: low ? context.palette.danger : null),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          clockLabel(Duration(seconds: _remaining.clamp(0, 1 << 30)), context.lang),
                          style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()], color: low ? context.palette.danger : null),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: a.answeredCount / a.questionIds.length),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                  child: q == null
                      ? EmptyState(title: context.tr(S.notFound))
                      : ListView(
                          padding: AppSpacing.screen,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${context.tr(S.questions)} ${context.n(a.currentIndex + 1)}/${context.n(a.questionIds.length)}',
                                  style: context.text.labelLarge,
                                ),
                                const Spacer(),
                                FilterChip(
                                  key: const Key('exam.review'),
                                  avatar: Icon(Icons.flag_outlined, size: 18, color: context.palette.warning),
                                  label: Text(context.tr(ExamStrings.markReview)),
                                  selected: ans.markedForReview,
                                  onSelected: (on) => _ctl.answer(a.id, qid, ans.copyWith(markedForReview: on)),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            QuestionMetaRow(question: q, showSource: false),
                            const SizedBox(height: AppSpacing.md),
                            QuestionPrompt(question: q, showOptions: false),
                            const SizedBox(height: AppSpacing.lg),
                            ..._answerInput(context, a, q, ans),
                            if (a.config.reviewPolicy == ReviewPolicy.immediate && ans.isAnswered) ...[
                              const SizedBox(height: AppSpacing.md),
                              AnswerPanel(question: q),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: Row(
                  children: [
                    IconButton.outlined(
                      tooltip: context.tr(S.previous),
                      onPressed: a.currentIndex == 0 ? null : () => _goTo(a, a.currentIndex - 1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    OutlinedButton.icon(
                      key: const Key('exam.palette'),
                      onPressed: () => _showPalette(a),
                      icon: const Icon(Icons.grid_view),
                      label: Text('${context.n(a.answeredCount)}/${context.n(a.questionIds.length)}'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton.outlined(
                      key: const Key('exam.next'),
                      tooltip: context.tr(S.next),
                      onPressed: a.currentIndex == a.questionIds.length - 1 ? null : () => _goTo(a, a.currentIndex + 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('exam.submit'),
                      onPressed: _submitting ? null : () => _confirmSubmit(a),
                      child: Text(context.tr(ExamStrings.submit)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _answerInput(BuildContext context, ExamAttempt a, Question q, ExamAnswer ans) {
    final immediate = a.config.reviewPolicy == ReviewPolicy.immediate && ans.isAnswered;
    if (q.type == QuestionType.mcq || q.type == QuestionType.trueFalse) {
      return [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: ans.choice == i
                  ? (immediate
                      ? (q.isCorrectChoice(i) ? context.palette.successContainer : context.palette.dangerContainer)
                      : context.colors.primaryContainer.withValues(alpha: 0.6))
                  : context.colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.field,
                side: BorderSide(color: ans.choice == i ? context.colors.primary : context.colors.outlineVariant, width: ans.choice == i ? 2 : 1),
              ),
              child: InkWell(
                key: Key('exam.option.$i'),
                borderRadius: AppRadius.field,
                onTap: immediate ? null : () => _ctl.answer(a.id, q.id, ans.copyWith(choice: () => ans.choice == i ? null : i)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 14, child: Text(optionLabel(context, i))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: InlineRich(context.tr(q.options[i]), style: context.text.bodyLarge!)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ];
    }
    final written = q.type != QuestionType.fillBlank;
    return [
      TextField(
        key: const Key('exam.text'),
        controller: _text,
        minLines: written ? 5 : 1,
        maxLines: written ? 12 : 1,
        readOnly: immediate && !written,
        decoration: InputDecoration(labelText: context.tr(ExamStrings.writeAnswer), alignLabelWithHint: true),
        onChanged: (v) {
          _textDebounce?.cancel();
          _textDebounce = Timer(const Duration(milliseconds: 400), () {
            final fresh = ref.read(examProvider).attempt(a.id)?.answerFor(q.id) ?? ans;
            _ctl.answer(a.id, q.id, fresh.copyWith(text: v));
          });
        },
      ),
      if (written) ...[
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickImage(a, q, ans, ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(context.tr(ExamStrings.uploadHandwritten)),
            ),
            IconButton(
              tooltip: context.tr(S.upload),
              onPressed: () => _pickImage(a, q, ans, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
            ),
          ],
        ),
        if (ans.imagePaths.isNotEmpty) ...[
          Text(context.tr(ExamStrings.imagesAttached.fill({'n': ans.imagePaths.length})), style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in ans.imagePaths)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.field,
                          child: Image.file(File(p), width: 84, height: 84, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(width: 84, height: 84, color: context.colors.surfaceContainerHigh, child: const Icon(Icons.image_not_supported_outlined))),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton.filledTonal(
                            iconSize: 16,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _ctl.answer(a.id, q.id, ans.copyWith(imagePaths: ans.imagePaths.where((x) => x != p).toList())),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ];
  }

  Future<void> _pickImage(ExamAttempt a, Question q, ExamAnswer ans, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      await _ctl.answer(a.id, q.id, ans.copyWith(imagePaths: [...ans.imagePaths, file.path]));
    } on PlatformException catch (_) {
      if (mounted) context.showSnack(const Tr('ক্যামেরা/গ্যালারির অনুমতি পাওয়া যায়নি।', 'Camera/gallery permission was denied.'));
    }
  }

  Future<void> _showPalette(ExamAttempt a) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(ExamStrings.palette), style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              _Legend(color: context.colors.primary, label: context.tr(ExamStrings.answered)),
              _Legend(color: context.palette.warning, label: context.tr(ExamStrings.markReview)),
              _Legend(color: context.colors.outlineVariant, label: context.tr(ExamStrings.notAnswered)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < a.questionIds.length; i++)
                Builder(builder: (context) {
                  final ans = a.answerFor(a.questionIds[i]);
                  final color = ans.markedForReview
                      ? context.palette.warning
                      : ans.isAnswered
                          ? context.colors.primary
                          : context.colors.outlineVariant;
                  return Semantics(
                    button: true,
                    label: '${context.tr(S.questions)} ${i + 1}',
                    child: InkWell(
                      key: Key('palette.$i'),
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.pop(context);
                        _goTo(a, i);
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: ans.isAnswered || ans.markedForReview ? color : Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: i == a.currentIndex ? context.colors.onSurface : color, width: i == a.currentIndex ? 2.5 : 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            context.n(i + 1),
                            style: TextStyle(color: ans.isAnswered || ans.markedForReview ? Colors.white : context.colors.onSurface),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [CircleAvatar(radius: 6, backgroundColor: color), const SizedBox(width: AppSpacing.xs), Text(label, style: context.text.labelSmall)],
  );
}

class _Instructions extends StatelessWidget {
  const _Instructions({required this.attempt, required this.onBegin});

  final ExamAttempt attempt;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    final c = attempt.config;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(attempt.title))),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: [
                  _Fact(icon: Icons.help_outline, label: context.tr(ExamStrings.questions.fill({'n': attempt.questionIds.length}))),
                  _Fact(icon: Icons.timer_outlined, label: context.tr(ExamStrings.minutes.fill({'n': c.timeLimitMinutes}))),
                  _Fact(icon: Icons.school_outlined, label: context.tr(c.mode.label)),
                  if (c.negativeMarking) _Fact(icon: Icons.remove_circle_outline, label: context.tr(ExamStrings.negative)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.tr(ExamStrings.instructions), style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final line in ExamStrings.instructionLines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(context.tr(line))),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(key: const Key('exam.begin'), onPressed: onBegin, icon: const Icon(Icons.play_arrow), label: Text(context.tr(ExamStrings.begin))),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 20, color: context.colors.primary), const SizedBox(width: AppSpacing.xs), Text(label)],
  );
}
