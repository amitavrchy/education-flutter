import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/application/tutor_controller.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/data/remote_tutor.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/domain/tutor_models.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

const _sid = 'u-student-1';

Map<String, dynamic> _assistant(String id, String convo, String text) => {
  'id': id, 'conversationId': convo, 'role': 'assistant', 'content': text, 'status': 'complete', 'mode': 'socratic',
  'createdAt': '2026-11-26T03:00:05.000Z', 'grounding': 'partial', 'confidence': 0.75, 'followUps': ['আরও বলো'],
  'relatedQuestionIds': <String>[], 'warnings': ['low_confidence', 'unknown_flag'], 'feedback': 'down', 'simulated': true,
  'citations': [
    {'id': 'cit-1', 'passageId': 'psg-ssc-math-c3-t3', 'bookTitle': 'সাধারণ গণিত', 'chapterTitle': 'বীজগাণিতিক রাশি', 'page': 15, 'excerpt': 'ভাগশেষ', 'curriculumVersionId': 'cv-2012r', 'score': 0.2},
  ],
};

void main() {
  test('server conversations map onto the app model', () {
    final c = RemoteTutor.conversationFrom(
      {
        'id': 'cv-1', 'title': 'ত্বরণ কী?', 'pinned': true, 'folderId': 'fld-1', 'createdAt': '2026-11-23T03:00:00.000Z',
        'context': {'mode': 'board', 'grade': 9, 'language': 'bn', 'levelCode': 'SSC', 'subjectId': 'ssc-physics', 'paperId': 'ssc-physics-p2'},
      },
      [
        _assistant('msg-2', 'cv-1', 'উত্তর'),
        {'id': 'msg-1', 'conversationId': 'cv-1', 'role': 'user', 'content': 'প্রশ্ন', 'createdAt': '2026-11-26T03:00:00.000Z', 'status': 'complete'},
      ],
      {'fld-1': 'পরীক্ষার প্রস্তুতি'},
    );
    expect(c.context.mode, TeachingMode.boardAnswer);
    expect(c.context.classYear, 9);
    expect(c.context.paper, 2);
    expect(c.folder, 'পরীক্ষার প্রস্তুতি');
    expect(c.messages.map((m) => m.id), ['msg-1', 'msg-2']);
    final a = c.messages.last;
    expect(a.sources.single.bookId, 'book-ssc-math');
    expect(a.warnings, [AnswerWarning.lowConfidence]);
    expect(a.feedback, -1);
    expect(RemoteTutor.serverMode(TeachingMode.stepByStep), 'stepwise');
  });

  test('API mode: a new conversation is created on the server and answers use server ids', () async {
    final server = FakeServer({'/conversations/$_sid': const [], '/messages/$_sid': const [], '/folders/$_sid': const []});
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteProgressProvider.overrideWithValue(RemoteProgress(server.client, _sid)),
    ]);
    c.read(tutorProvider);
    final ctl = c.read(tutorProvider.notifier);
    await ctl.refresh();
    expect(c.read(tutorProvider), isEmpty); // no demo seed in API mode

    final convo = await ctl.create();
    expect(server.calls, contains('POST /conversations/$_sid'));
    server.responses['POST /tutor/$_sid/conversations/${convo.id}/messages'] = {
      'user': {'id': 'msg-u1', 'conversationId': convo.id, 'role': 'user', 'content': 'ত্বরণ কী?', 'createdAt': '2026-11-26T03:00:00.000Z', 'status': 'complete'},
      'assistant': _assistant('msg-a1', convo.id, 'বেগের পরিবর্তনের হার'),
    };
    await ctl.send(convo.id, 'ত্বরণ কী?');
    final msgs = ctl.byId(convo.id)!.messages;
    expect(msgs.map((m) => m.id), ['msg-u1', 'msg-a1']);
    expect(msgs.last.text, 'বেগের পরিবর্তনের হার');
    expect(msgs.last.status, MessageStatus.done);
    expect(msgs.last.sources, hasLength(1));

    await ctl.setFeedback(convo.id, 'msg-a1', 1);
    await ctl.rename(convo.id, 'গতি');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(server.lastBody['/messages/$_sid/msg-a1'], {'feedback': 'up'});
    expect(server.lastBody['/conversations/$_sid/${convo.id}'], {'title': 'গতি'});
  });
}
