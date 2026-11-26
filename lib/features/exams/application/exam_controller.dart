import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/tr.dart';
import '../../../core/mock/json_collection.dart';
import '../../../core/mock/mock_simulator.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/utils/bangla_number.dart';
import '../../../mock/seed/exams_seed.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../notifications/domain/app_notification.dart';
import '../../progress/application/learning_progress_controller.dart';
import '../../progress/domain/learning_progress.dart';
import '../../question_bank/application/practice_controller.dart';
import '../../question_bank/data/question_repository.dart';
import '../../question_bank/domain/question.dart';
import '../../../core/network/network_providers.dart';
import '../../progress/data/remote_progress.dart';
import '../data/remote_exams.dart';
import '../domain/exam.dart';
import 'exam_scoring.dart';

@immutable
class ExamState {
  const ExamState({required this.templates, required this.attempts});

  final List<ExamTemplate> templates;

  /// Newest first.
  final List<ExamAttempt> attempts;

  List<ExamAttempt> get inProgress => attempts.where((a) => a.status == AttemptStatus.inProgress).toList();
  List<ExamAttempt> get finished => attempts.where((a) => a.isFinished && a.result != null).toList();
  ExamAttempt? attempt(String id) => attempts.where((a) => a.id == id).firstOrNull;

  /// Templates the student has not completed yet.
  List<ExamTemplate> get open => templates.where((t) => !finished.any((a) => a.templateId == t.id)).toList();
}

/// Exam lifecycle: start → answer (autosaved) → submit/expire → result. Submitting feeds
/// practice history and topic mastery, logs study time and raises a result notification.
class ExamController extends Notifier<ExamState> {
  late JsonCollection<ExamTemplate> _templates;
  late JsonCollection<ExamAttempt> _attempts;
  RemoteExams? _remote;
  Timer? _saveTimer;
  final Set<String> _dirty = {};
  Future<void>? _refreshing;

  @override
  ExamState build() {
    final store = watchStore(ref);
    final progress = ref.watch(remoteProgressProvider);
    _remote = progress == null ? null : RemoteExams(ref.read(apiClientProvider), progress.studentId);
    ref.onDispose(() => _saveTimer?.cancel());
    _templates = JsonCollection<ExamTemplate>(
      store: store,
      name: 'exam_templates',
      fromJson: ExamTemplate.fromJson,
      toJson: (t) => t.toJson(),
      idOf: (t) => t.id,
      seed: _remote == null ? seedExamTemplates : () => const [],
    );
    _attempts = JsonCollection<ExamAttempt>(
      store: store,
      name: 'exam_attempts',
      fromJson: ExamAttempt.fromJson,
      toJson: (a) => a.toJson(),
      idOf: (a) => a.id,
      seed: _remote == null ? seedExamAttempts : () => const [],
    );
    final templates = _templates.all()..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    if (_remote != null) Future.microtask(refresh);
    return ExamState(templates: templates, attempts: _sortedAttempts(_attempts.all()));
  }

  /// API mode: offered exams and the student's attempts come from the server (single-flight).
  Future<void> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<void> _refresh() async {
    final remote = _remote;
    if (remote == null || !ref.mounted) return;
    try {
      final (exams, attempts) = await (remote.exams(), remote.attempts()).wait;
      if (!ref.mounted) return;
      final byId = {for (final e in exams) e['id'] as String: e};
      final templates = [for (final e in exams) if (RemoteExams.isOffered(e)) RemoteExams.templateFrom(e)]
        ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      final questions = _questionMap;
      // Unsaved local answers win over the server copy of an attempt in progress.
      final mapped = [
        for (final a in attempts)
          if (_dirty.contains(a['id'])) ?state.attempt(a['id'] as String) else RemoteExams.attemptFrom(a, exams: byId, questions: questions),
      ];
      final store = ref.read(localStoreProvider);
      await store.clearCollection('exam_templates');
      await store.clearCollection('exam_attempts');
      await _templates.upsertAll(templates);
      await _attempts.upsertAll(mapped);
      state = ExamState(templates: templates, attempts: _sortedAttempts(mapped));
    } catch (_) {
      // Offline: keep the cached exams.
    }
  }

  /// Server questions the device doesn't have yet (e.g. new uploads) are added to the bank.
  Future<void> _ensureQuestions(String attemptId, List<String> ids) async {
    final have = _questionMap;
    if (ids.every(have.containsKey)) return;
    for (final q in await _remote!.questions(attemptId)) {
      if (!have.containsKey(q.id)) await _questions.save(q);
    }
  }

  Future<ExamAttempt> _startRemote(ExamTemplate? template, ExamConfig cfg, ExamType type, Tr? title) async {
    final remote = _remote!;
    if (template?.scheduledAt != null && template!.scheduledAt!.isAfter(DateTime.now())) {
      throw const ApiException.forbidden('পরীক্ষাটি এখনো শুরু হয়নি।');
    }
    final id = template != null
        ? await remote.startExam(template.id)
        : type == ExamType.dailyChallenge
        ? await remote.startDaily(levelCode: (cfg.subjectId ?? '').startsWith('hsc') ? 'HSC' : 'SSC')
        : await remote.startCustom(cfg, type, title);
    final raw = await remote.attempt(id);
    final order = [for (final q in raw['questionOrder'] as List? ?? const []) q as String];
    await _ensureQuestions(id, order);
    final mapped = RemoteExams.attemptFrom(raw, exams: const {}, questions: _questionMap);
    final attempt = ExamAttempt(
      id: mapped.id,
      type: template?.type ?? type,
      title: template?.title ?? (title ?? mapped.title),
      config: template?.config ?? cfg.copyWith(questionCount: order.length),
      questionIds: mapped.questionIds,
      startedAt: mapped.startedAt,
      templateId: template?.id,
      answers: mapped.answers,
      currentIndex: mapped.currentIndex,
      remainingSeconds: mapped.remainingSeconds,
    );
    await _save(attempt);
    return attempt;
  }

  /// Debounced autosave of answers, review flags and position (the server keeps the timer).
  void _schedulePush(String attemptId) {
    if (_remote == null) return;
    _dirty.add(attemptId);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 1500), _flush);
  }

  Future<void> _flush() async {
    _saveTimer?.cancel();
    final remote = _remote;
    if (remote == null) return;
    final questions = _questionMap;
    for (final id in _dirty.toList()) {
      final a = state.attempt(id);
      _dirty.remove(id);
      if (a == null || a.isFinished) continue;
      try {
        await remote.save(
          id,
          answers: RemoteExams.answersToApi(a, questions),
          marked: [for (final e in a.answers.entries) if (e.value.markedForReview) e.key],
          currentIndex: a.currentIndex,
        );
      } catch (_) {
        _dirty.add(id); // retried with the next change or on submit
      }
    }
  }

  List<ExamAttempt> _sortedAttempts(List<ExamAttempt> list) => list..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  QuestionRepository get _questions => ref.read(questionRepositoryProvider);

  Map<String, Question> get _questionMap => {for (final q in _questions.cached) q.id: q};

  /// Starts an attempt from a template or an ad-hoc config. Throws when no questions match.
  Future<ExamAttempt> start({ExamTemplate? template, ExamConfig? config, ExamType type = ExamType.custom, Tr? title}) async {
    final cfg = template?.config ?? config ?? const ExamConfig();
    final examType = template?.type ?? type;
    final now = DateTime.now();
    if (_remote != null) return _startRemote(template, cfg, examType, title);
    return ref.read(mockSimulatorProvider).run(() async {
      if (template?.scheduledAt != null && template!.scheduledAt!.isAfter(now)) {
        throw const ApiException.forbidden('পরীক্ষাটি এখনো শুরু হয়নি।');
      }
      final all = _questions.cached;
      final List<Question> picked;
      if (template != null && template.questionIds.isNotEmpty) {
        final map = _questionMap;
        picked = [for (final id in template.questionIds) ?map[id]].take(cfg.questionCount).toList();
      } else {
        final progress = ref.read(learningProgressProvider);
        picked = selectExamQuestions(
          cfg,
          all,
          seed: examType == ExamType.dailyChallenge ? now.year * 400 + now.month * 31 + now.day : now.millisecondsSinceEpoch,
          masteryOf: examType == ExamType.adaptive ? (id) => progress.topic(id).mastery : null,
        );
      }
      if (picked.isEmpty) throw const ApiException.validation('এই শর্তে কোনো প্রশ্ন পাওয়া যায়নি।');
      final attempt = ExamAttempt(
        id: 'att-${now.microsecondsSinceEpoch}',
        type: examType,
        title: template?.title ?? title ?? examType.label,
        config: cfg,
        questionIds: [for (final q in picked) q.id],
        startedAt: now,
        templateId: template?.id,
        remainingSeconds: cfg.timeLimitMinutes * 60,
      );
      await _save(attempt);
      return attempt;
    }, requiresNetwork: false);
  }

  Future<void> _save(ExamAttempt a) async {
    final others = state.attempts.where((x) => x.id != a.id).toList();
    state = ExamState(templates: state.templates, attempts: _sortedAttempts([a, ...others]));
    await _attempts.upsert(a);
  }

  Future<void> answer(String attemptId, String questionId, ExamAnswer answer) async {
    final a = state.attempt(attemptId);
    if (a == null || a.isFinished) return;
    await _save(a.copyWith(answers: {...a.answers, questionId: answer}));
    _schedulePush(attemptId);
  }

  Future<void> goTo(String attemptId, int index) async {
    final a = state.attempt(attemptId);
    if (a == null || a.isFinished) return;
    await _save(a.copyWith(currentIndex: index));
    _schedulePush(attemptId);
  }

  /// Timer autosave so a recovered session keeps the right remaining time.
  Future<void> saveRemaining(String attemptId, int seconds) async {
    final a = state.attempt(attemptId);
    if (a == null || a.isFinished) return;
    await _save(a.copyWith(remainingSeconds: seconds));
  }

  Future<void> discard(String attemptId) async {
    state = ExamState(templates: state.templates, attempts: state.attempts.where((a) => a.id != attemptId).toList());
    await _attempts.remove(attemptId);
    _dirty.remove(attemptId);
    if (_remote != null) {
      try {
        await _remote!.discard(attemptId);
      } catch (_) {
        // Already submitted or offline: the next refresh shows the server's copy.
      }
    }
  }

  /// Scores the attempt and propagates the results to the rest of the app.
  Future<ExamAttempt> submit(String attemptId, {bool expired = false}) async {
    final a = state.attempt(attemptId);
    if (a == null) throw const ApiException.notFound();
    if (a.isFinished) return a;
    if (_remote != null) return _submitRemote(a, expired: expired);
    final now = DateTime.now();
    final limit = a.config.timeLimitMinutes * 60;
    final spent = expired ? limit : (limit - (a.remainingSeconds ?? limit)).clamp(1, limit);
    final questions = _questionMap;
    final template = state.templates.where((t) => t.id == a.templateId).firstOrNull;
    var result = scoreAttempt(a, questions, timeSpentSeconds: spent);
    if (template?.type == ExamType.teacherAssigned) {
      result = ExamResult(
        scores: result.scores,
        timeSpentSeconds: result.timeSpentSeconds,
        teacherFeedback: const Tr(
          'শিক্ষক এখনো মূল্যায়ন করছেন। লিখিত উত্তরের চূড়ান্ত নম্বর শিক্ষক দেবেন।',
          'Your teacher is still reviewing. Final marks for written answers come from your teacher.',
        ),
      );
    }
    final done = a.copyWith(status: expired ? AttemptStatus.expired : AttemptStatus.submitted, submittedAt: now, result: result);
    await _save(done);

    // Cross-module effects: practice history + mastery, study time, notification.
    final practice = ref.read(practiceProvider.notifier);
    for (final s in result.scores) {
      final q = questions[s.questionId];
      if (q == null || s.outcome == Outcome.unanswered) continue;
      final correct = s.outcome == Outcome.correct || (s.outcome == Outcome.estimated && s.marks >= s.maxMarks / 2);
      await practice.recordAttempt(q, correct: correct, context: 'exam');
    }
    await ref.read(learningProgressProvider.notifier).logActivity(
      ActivityKind.exam,
      minutes: (spent / 60).ceil(),
      xp: 10 + (result.percent * 40).round(),
      subjectId: a.config.subjectId,
    );
    final pct = (result.percent * 100).round();
    await ref.read(notificationsProvider.notifier).push(AppNotification(
      id: 'exam-${a.id}',
      category: NotificationCategory.exam,
      title: Tr('ফলাফল: ${a.title.bn}', 'Result: ${a.title.en}'),
      body: Tr('তুমি ${toBanglaDigits(pct)}% নম্বর পেয়েছ। বিস্তারিত বিশ্লেষণ দেখো।', 'You scored $pct%. See the detailed analysis.'),
      createdAt: now,
      route: '/student/practice/results/${a.id}',
      audience: 'student',
    ));
    return done;
  }

  /// The server scores the attempt and records progress, XP and the result notification, so
  /// the app only reloads those.
  Future<ExamAttempt> _submitRemote(ExamAttempt a, {required bool expired}) async {
    _saveTimer?.cancel();
    _dirty.remove(a.id);
    final raw = await _remote!.submit(a.id, answers: RemoteExams.answersToApi(a, _questionMap), expired: expired);
    final scored = RemoteExams.attemptFrom(raw, exams: const {}, questions: _questionMap);
    final done = a.copyWith(
      status: scored.status == AttemptStatus.inProgress ? AttemptStatus.submitted : scored.status,
      submittedAt: scored.submittedAt ?? DateTime.now(),
      result: scored.result,
    );
    await _save(done);
    unawaited(ref.read(learningProgressProvider.notifier).refresh());
    unawaited(ref.read(notificationsProvider.notifier).refresh());
    return done;
  }

  /// Teachers publish new exams (used by the role portals).
  Future<void> publishTemplate(ExamTemplate t) async {
    state = ExamState(templates: [t, ...state.templates.where((x) => x.id != t.id)], attempts: state.attempts);
    await _templates.upsert(t);
  }
}

final examProvider = NotifierProvider<ExamController, ExamState>(ExamController.new);
