import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/teacher/remote_review.dart';
import 'package:shikkhaai_mobile/features/teacher/review_data.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

Map<String, dynamic> _item(String status, {List<Map<String, dynamic>> extraHistory = const []}) => {
  'id': 'rv-1', 'contentType': 'board_paper', 'contentId': 'bp-1', 'title': 'ঢাকা বোর্ড ২০২৪', 'subjectId': 'ssc-phy', 'status': status,
  'priority': 'high', 'preview': 'প্রশ্ন ১: বল কী?', 'createdAt': '2026-11-20T03:00:00.000Z',
  'submittedBy': {'id': 'u-teacher-1', 'name': 'নাসরিন সুলতানা', 'role': 'teacher'},
  'comments': [{'id': 'c1', 'author': {'id': 'u-r', 'name': 'ড. মাহমুদ', 'role': 'content_reviewer'}, 'text': 'ঠিক আছে', 'at': '2026-11-21T03:00:00.000Z'}],
  'suggestions': <Object>[],
  'history': [
    {'at': '2026-11-20T03:00:00.000Z', 'from': null, 'to': 'submitted', 'by': {'id': 'u-teacher-1', 'name': 'নাসরিন সুলতানা', 'role': 'teacher'}},
    ...extraHistory,
  ],
};

void main() {
  test('API mode: queue and rubrics load from the server; moves use the server result', () async {
    final server = FakeServer({
      '/review-items': [_item('submitted')],
      '/rubrics': [
        {'id': 'rb-1', 'name': 'সৃজনশীল', 'appliesTo': 'creative', 'status': 'published', 'owner': 'নাসরিন', 'criteria': [{'criterion': 'জ্ঞান', 'marks': 1, 'description': ''}]},
        {'id': 'rb-2', 'name': 'স্পিকিং', 'appliesTo': 'speaking', 'status': 'draft', 'owner': 'নাসরিন', 'criteria': <Object>[]},
      ],
    });
    server.responses['POST /review-items/rv-1/transition'] = _item('in_review', extraHistory: [
      {'at': '2026-11-22T03:00:00.000Z', 'from': 'submitted', 'to': 'in_review', 'by': {'id': 'u-r', 'name': 'ড. মাহমুদ', 'role': 'content_reviewer'}},
    ]);
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteReviewProvider.overrideWithValue(RemoteReview(server.client)),
    ]);
    c.read(reviewProvider);
    final ctl = c.read(reviewProvider.notifier);
    await ctl.refresh();
    final s = c.read(reviewProvider);
    expect(s.queue.single.kind, ReviewKind.boardPaper);
    expect(s.queue.single.comments.single.author.role, ActorRole.reviewer);
    expect(s.rubrics.map((r) => r.use), [RubricUse.creative, RubricUse.essay]);

    await ctl.transition('rv-1', ContentStatus.inReview);
    expect(server.lastBody['/review-items/rv-1/transition'], {'to': 'in_review'});
    final item = c.read(reviewProvider).item('rv-1')!;
    expect(item.status, ContentStatus.inReview);
    expect(item.history.last.by.name, 'ড. মাহমুদ');
  });
}
