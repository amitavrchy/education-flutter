import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/network_providers.dart';
import 'package:shikkhaai_mobile/features/teacher/remote_teacher.dart';
import 'package:shikkhaai_mobile/features/teacher/teacher_data.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

FakeServer _server() => FakeServer({
  '/class-groups': [
    {'id': 'cg-10a', 'grade': 10, 'section': 'ক', 'institutionId': 'inst-1', 'subjectIds': ['ssc-phy', 'ssc-chem'], 'studentIds': ['im-s-1', 'im-s-2']},
  ],
  '/institution-members': [
    {'id': 'im-s-1', 'kind': 'student', 'name': 'রাফি আহমেদ', 'userId': 'u-student-1'},
    {'id': 'im-s-2', 'kind': 'student', 'name': 'নুসাইবা খান'},
  ],
  '/teacher-profiles': [
    {'id': 'tp-1', 'userId': 'u-teacher-1', 'subjectIds': ['ssc-phy']},
  ],
  '/assignments': [
    {'id': 'as-1', 'title': 'বলের সমস্যা', 'subjectId': 'ssc-phy', 'classGroupIds': ['cg-10a'], 'dueAt': '2026-11-28T16:00:00.000Z', 'totalMarks': 10, 'status': 'assigned', 'instructions': ''},
  ],
  '/submissions': [
    {'id': 'sub-1', 'assignmentId': 'as-1', 'studentId': 'u-student-1', 'studentName': 'রাফি আহমেদ', 'status': 'submitted', 'submittedAt': '2026-11-24T13:00:00.000Z'},
  ],
  '/institution-resources': [
    {'id': 'res-1', 'title': 'গতি স্লাইড', 'kind': 'slide', 'subjectId': 'ssc-phy', 'createdAt': '2026-11-12T03:00:00.000Z'},
  ],
  '/teacher-feedback': [
    {'id': 'tf-1', 'studentId': 'u-student-1', 'text': 'ভালো করছে', 'at': '2026-11-22T03:00:00.000Z'},
  ],
  '/evaluations/u-student-1': [
    {'id': 'ev-1', 'studentName': 'রাফি আহমেদ', 'title': 'নিউটনের সূত্র', 'subjectId': 'ssc-phy', 'stage': 'teacher_review_requested', 'aiMarks': 6.5, 'maxMarks': 10, 'pages': [{'id': 'p1'}, {'id': 'p2'}], 'rubric': <Object>[]},
    {'id': 'ev-2', 'studentName': 'রাফি আহমেদ', 'title': 'প্রক্রিয়াধীন', 'subjectId': 'ssc-phy', 'stage': 'processing', 'maxMarks': 10},
  ],
});

void main() {
  test('API mode: roster, assignments, scripts, resources and feedback come from the server', () async {
    final server = _server();
    final c = testContainer(overrides: [
      apiClientProvider.overrideWithValue(server.client),
      remoteTeacherProvider.overrideWithValue(RemoteTeacher(server.client, teacherId: 'u-teacher-1', teacherName: 'নাসরিন সুলতানা')),
    ]);
    c.read(teacherProvider);
    final ctl = c.read(teacherProvider.notifier);
    await ctl.refresh();

    expect(teacherClasses.map((x) => x.id), ['cg-10a:ssc-phy']); // only the subject this teacher teaches
    expect(teacherClasses.single.students, ['রাফি আহমেদ', 'নুসাইবা খান']);
    final s = c.read(teacherProvider);
    final work = s.assignments.single.work();
    expect({for (final w in work) w.student: w.status}, {'রাফি আহমেদ': WorkStatus.submitted, 'নুসাইবা খান': WorkStatus.missing});
    expect(s.submissions.map((x) => x.id), ['ev-1']);
    expect(s.pending.single.pages, 2);
    expect(s.materials.single.kind, 'pdf');
    expect(s.notes.single.student, 'রাফি আহমেদ');

    await ctl.gradeWork('as-1', 'রাফি আহমেদ', 8, 'ভালো');
    expect(server.lastBody['/submissions/sub-1'], {'marks': 8.0, 'feedback': 'ভালো', 'status': 'graded', 'gradedBy': 'নাসরিন সুলতানা'});
    expect(c.read(teacherProvider).assignments.single.work().first.grade, 8);

    await ctl.review('ev-1', 7.5, 'একক লেখো', official: true);
    final review = server.lastBody['/evaluations/u-student-1/ev-1']! as Map;
    expect(review['stage'], 'official');
    expect(review['officialMarks'], 7.5);

    await ctl.sendStudentFeedback('রাফি আহমেদ', 'চমৎকার');
    expect((server.lastBody['/teacher-feedback']! as Map)['studentId'], 'u-student-1');
    await expectLater(ctl.sendStudentFeedback('নুসাইবা খান', 'x'), throwsA(anything)); // no app account
  });

  tearDown(() => TeacherRoster.classes = demoTeacherClasses);
}
