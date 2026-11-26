import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/exams/application/exam_controller.dart';
import 'package:shikkhaai_mobile/features/exams/data/remote_exams.dart';
import 'package:shikkhaai_mobile/features/exams/domain/exam.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

const _sid = 'u-student-1';

Map<String, dynamic> _exam(String id, String kind, {String status = 'published', List<String> questionIds = const []}) => {
  'id': id, 'kind': kind, 'title': 'মডেল টেস্ট ১', 'status': status, 'durationMinutes': 20, 'totalMarks': 12,
  'questionIds': questionIds, 'questionTypes': ['mcq', 'true_false'], 'difficulty': 'mixed', 'negativeMarking': 0.25,
  'mode': 'exam', 'randomize': true, 'reviewPolicy': 'after_submit', 'chapterIds': <String>[], 'instructions': ['সময় ২০ মিনিট'],
  'createdBy': {'id': 'u-teacher-1', 'name': 'রহিম স্যার', 'role': 'teacher'}, 'createdAt': '2026-11-20T03:00:00.000Z',
};

Map<String, dynamic> _attempt(String status, {Map<String, dynamic>? result}) => {
  'id': 'att-1', 'examId': 'ex-model', 'examTitle': 'মডেল টেস্ট ১', 'studentId': _sid,
  'questionOrder': ['q-phy-m1', 'q-phy-f6', 'q-chem-r2'], 'startedAt': DateTime.now().toUtc().toIso8601String(),
  'status': status, 'answers': <String, dynamic>{}, 'markedForReview': <String>[], 'currentIndex': 0, 'remainingSec': 1200,
  'result': ?result,
};

void main() {
  test('server exam records map to templates, attempts and results', () {
    final t = RemoteExams.templateFrom(_exam('ex-model', 'model_test'));
    expect(t.type, ExamType.modelTest);
    expect(t.config.questionCount, 10); // 12 marks / 1.2, as the server draws
    expect(t.config.negativeMarking, isTrue);
    expect(t.assignedBy?.bn, 'রহিম স্যার');
    expect(RemoteExams.isOffered(_exam('x', 'custom')), isFalse);

    final a = RemoteExams.attemptFrom({
      ..._attempt('submitted', result: {
        'timeSpentSec': 300,
        'questions': [
          {'questionId': 'q-phy-m1', 'status': 'correct', 'awarded': 1, 'max': 1},
          {'questionId': 'q-phy-f6', 'status': 'incorrect', 'awarded': -0.25, 'max': 1},
          {'questionId': 'q-chem-r2', 'status': 'pending_review', 'awarded': 1.5, 'max': 2},
        ],
      }),
      'answers': {'q-phy-m1': {'optionId': 'b'}, 'q-phy-f6': {'booleanValue': false}, 'q-chem-r2': {'text': 'উত্তর'}},
    }, exams: {'ex-model': _exam('ex-model', 'model_test')});
    expect(a.type, ExamType.modelTest);
    expect(a.templateId, 'ex-model');
    expect(a.answers['q-phy-m1']!.choice, 1);
    expect(a.answers['q-phy-f6']!.choice, 1);
    expect(a.result!.count(Outcome.estimated), 1);
    expect(a.result!.score, 2.25);
  });

  test('API mode: start, autosave and submit go through the server', () async {
    final server = FakeServer({
      '/exams': [_exam('ex-model', 'model_test'), _exam('ex-daily', 'daily_challenge')],
      '/exam-attempts/$_sid': const [],
    });
    server.responses['POST /exams/ex-model/attempts'] = {'attemptId': 'att-1'};
    server.responses['GET /exam-attempts/$_sid/att-1'] = _attempt('in_progress');
    server.responses['POST /exam-attempts/$_sid/att-1/submit'] = _attempt('submitted', result: {
      'timeSpentSec': 120,
      'questions': [
        {'questionId': 'q-phy-m1', 'status': 'correct', 'awarded': 1, 'max': 1},
        {'questionId': 'q-phy-f6', 'status': 'correct', 'awarded': 1, 'max': 1},
        {'questionId': 'q-chem-r2', 'status': 'unanswered', 'awarded': 0, 'max': 2},
      ],
    });
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, _sid)),
    ]);
    c.read(examProvider);
    final ctrl = c.read(examProvider.notifier);
    await ctrl.refresh();
    expect(c.read(examProvider).templates.map((t) => t.id), ['ex-model']);

    final attempt = await ctrl.start(template: c.read(examProvider).templates.single);
    expect(attempt.id, 'att-1');
    expect(attempt.questionIds, hasLength(3));

    await ctrl.answer('att-1', 'q-phy-m1', const ExamAnswer(choice: 1));
    await ctrl.answer('att-1', 'q-phy-f6', const ExamAnswer(choice: 0, markedForReview: true));
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    final saved = server.lastBody['/exam-attempts/$_sid/att-1']! as Map;
    expect(saved['answers'], {'q-phy-m1': {'optionId': 'b'}, 'q-phy-f6': {'booleanValue': true}});
    expect(saved['markedForReview'], ['q-phy-f6']);

    final done = await ctrl.submit('att-1');
    expect(done.status, AttemptStatus.submitted);
    expect(done.result!.score, 2);
    expect((server.lastBody['/exam-attempts/$_sid/att-1/submit']! as Map)['reason'], 'manual');
    // The server records progress for exam answers; the app must not post them again.
    expect(server.calls.where((x) => x.startsWith('POST /progress')), isEmpty);
  });
}
