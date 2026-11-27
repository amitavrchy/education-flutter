import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/ai_tools/remote_ai_tools.dart';
import 'package:shikkhaai_mobile/features/study_tools/english_coach.dart';

import '../../helpers/fake_server.dart';

void main() {
  test('AI tools call the backend and map the answers', () async {
    final server = FakeServer();
    server.responses['POST /solve/u-student-1'] = {'steps': ['v = u + at', 'v = 0 + 2×5'], 'answer': '10 m/s', 'explanation': 'সমত্বরণ'};
    server.responses['POST /voice/u-student-1/reply'] = {'text': 'ভালো উত্তর। পরের প্রশ্ন: বল কী?', 'nextQuestion': 'বল কী?', 'score': {'got': 2, 'max': 3}};
    server.responses['POST /flashcards/u-student-1/generate'] = {'cards': [{'front': 'ত্বরণ কী?', 'back': 'বেগ পরিবর্তনের হার', 'tags': <String>[]}]};
    server.responses['POST /notes/u-student-1/generate'] = {'title': 'গতি', 'html': '<h2>গতি</h2><ul><li>ত্বরণ</li></ul>'};
    server.responses['POST /english/u-student-1/writing'] = {
      'overall': 62, 'scores': {'grammar': 50, 'vocabulary': 70, 'structure': 60, 'task': 68},
      'issues': [{'text': 'I goes', 'why': 'subject-verb agreement', 'fix': 'I go'}], 'strengths': ['Clear ideas'],
    };
    final tools = RemoteAiTools(server.client, 'u-student-1');

    final solution = await tools.solve('a = 2, t = 5, v?', subjectId: 'ssc-phy');
    expect(solution, contains('1. v = u + at'));
    expect(solution, contains('**উত্তর:** 10 m/s'));
    expect((server.lastBody['/solve/u-student-1']! as Map)['correctedText'], 'a = 2, t = 5, v?');

    final r = await tools.voiceReply(text: 'বেগের পরিবর্তন', oralExam: true, language: 'bn', oralQuestion: 'ত্বরণ কী?', turns: [(false, 'ত্বরণ কী?')]);
    expect((r.nextQuestion, r.got, r.max), ('বল কী?', 2, 3));
    final voiceBody = server.lastBody['/voice/u-student-1/reply']! as Map;
    expect(voiceBody['mode'], 'oral_exam');
    expect(voiceBody['turns'], [{'speaker': 'tutor', 'text': 'ত্বরণ কী?'}]);

    expect((await tools.flashcards('ssc-phy-c2')).single.front, 'ত্বরণ কী?');
    expect((await tools.note(kind: 'short', chapterId: 'ssc-phy-c2')).html, startsWith('<h2>'));

    final feedback = writingFeedbackText(await tools.writing('I goes to school.', kind: 'sentence'));
    expect(feedback, contains('**62/100**'));
    expect(feedback, contains('~~I goes~~ → **I go**'));
  });
}
