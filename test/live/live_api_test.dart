import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/l10n/tr.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';
import 'package:shikkhaai_mobile/core/network/owner_sync.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/account/remote_billing.dart';
import 'package:shikkhaai_mobile/features/ai_tutor/data/remote_tutor.dart';
import 'package:shikkhaai_mobile/features/archives/archive_data.dart';
import 'package:shikkhaai_mobile/features/archives/remote_archive.dart';
import 'package:shikkhaai_mobile/features/auth/data/auth_repository.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/remote_avatar.dart';
import 'package:shikkhaai_mobile/features/book_avatar/domain/avatar_models.dart';
import 'package:shikkhaai_mobile/features/curriculum/data/curriculum_catalog.dart';
import 'package:shikkhaai_mobile/features/exams/data/remote_exams.dart';
import 'package:shikkhaai_mobile/features/flashcards/data/remote_flashcards.dart';
import 'package:shikkhaai_mobile/features/notes/data/remote_notes.dart';
import 'package:shikkhaai_mobile/features/notifications/data/remote_notifications.dart';
import 'package:shikkhaai_mobile/features/planner/application/planner_controller.dart';
import 'package:shikkhaai_mobile/features/planner/data/remote_tasks.dart';
import 'package:shikkhaai_mobile/features/planner/domain/study_task.dart';
import 'package:shikkhaai_mobile/features/profile/data/remote_profile.dart';
import 'package:shikkhaai_mobile/features/profile/domain/student_profile.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';
import 'package:shikkhaai_mobile/features/parent/remote_guardian.dart';
import 'package:shikkhaai_mobile/features/insights/insights_engine.dart';
import 'package:shikkhaai_mobile/features/library/remote_reading.dart';
import 'package:shikkhaai_mobile/features/question_bank/application/practice_controller.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_mapper.dart';
import 'package:shikkhaai_mobile/features/study_tools/english_coach.dart';
import 'package:shikkhaai_mobile/features/teacher/remote_review.dart';
import 'package:shikkhaai_mobile/features/teacher/remote_teacher.dart';
import 'package:shikkhaai_mobile/mock/seed/curriculum_seed.dart';

/// Talks to a running education-backend (demo mode). Skipped unless LIVE_API=1:
///   LIVE_API=1 flutter test test/live
void main() {
  final live = Platform.environment['LIVE_API'] == '1';
  final base = Platform.environment['API_BASE_URL'] ?? 'http://localhost:4000/api/v1';
  ApiClient client([String? token]) => ApiClient(Dio(BaseOptions(baseUrl: base, headers: {if (token != null) 'Authorization': 'Bearer $token'})));

  // One student session for the data checks (login is rate-limited to 10/min).
  String? studentToken;
  Future<String> student() async => studentToken ??= (await ApiAuthRepository(client()).login(identifier: 'student@shikkha.ai', password: 'demo-password-123')).accessToken;

  test('demo accounts sign in with their role, refresh rotates, switch-role works', () async {
    final repo = ApiAuthRepository(client());
    for (final (id, role) in [('student@shikkha.ai', UserRole.student), ('teacher@shikkha.ai', UserRole.teacher), ('parent@shikkha.ai', UserRole.parent), ('reviewer@shikkha.ai', UserRole.teacher), ('admin@shikkha.ai', UserRole.superAdmin)]) {
      final s = await repo.login(identifier: id, password: 'demo-password-123');
      expect(s.user.role, role, reason: id);
    }
    final s = await repo.login(identifier: 'student@shikkha.ai', password: 'demo-password-123');
    final r = await repo.refresh(s.refreshToken!);
    expect(r.refreshToken, isNot(s.refreshToken));
    expect((await repo.switchRole(UserRole.parent)).user.role, UserRole.parent);
  }, skip: !live);

  test('signup: register → OTP challenge → verify with the demo code', () async {
    final repo = ApiAuthRepository(client());
    final phone = '0171${DateTime.now().millisecondsSinceEpoch % 10000000}'.padRight(11, '0').substring(0, 11);
    final ch = await repo.startRegistration(name: 'Live Test', identifier: phone, password: 'abcd1234', role: UserRole.student);
    expect(ch, isNotNull);
    final s = await repo.completeRegistration(challengeId: ch, code: '123456', name: 'Live Test', identifier: phone, password: 'abcd1234', role: UserRole.student);
    expect(s.user.role, UserRole.student);
  }, skip: !live);

  test('student inbox loads from /notifications and maps to app notifications', () async {
    final items = await RemoteNotifications(client(await student())).all();
    expect(items, isNotEmpty);
    expect(items.every((n) => RemoteNotifications.isServerId(n.id)), isTrue);
  }, skip: !live);

  test('billing: /billing/me parses and the declining test card fails', () async {
    final billing = RemoteBilling(client(await student()));
    final state = RemoteBilling.apply(const AccountState(), await billing.me());
    expect(state.invoices, isNotEmpty);
    expect(await billing.checkout(plan: PlanCode.pro, yearly: false, method: 'Card', account: '4000000000000002'), 'failed');
  }, skip: !live);

  test('full catalog sync: every server question points at a mapped chapter and topic', () async {
    final api = client(await student());
    Future<List<Map<String, dynamic>>> all(String p) async => (await api.get(p, query: {'all': true}, parse: (d) => [for (final x in d! as List) (x as Map).cast<String, dynamic>()])).data;
    final subjects = subjectsFromApi(subjects: await all('/subjects'), papers: await all('/papers'), chapters: await all('/chapters'), topics: await all('/topics'), outcomes: await all('/outcomes'));
    final chapters = {for (final x in subjects) for (final c in x.chapters) c.id};
    final topics = {for (final x in subjects) for (final c in x.chapters) for (final t in c.topics) t.id};
    final raw = await all('/questions');
    final questions = [for (final q in questionsWithKnownChapter(raw, subjects)) questionFromApi(q)];
    // ignore: avoid_print
    print('questions: ${raw.length} on the server, ${raw.length - questions.length} skipped (unknown chapter)');
    expect(subjects.length, greaterThan(20));
    expect(questions.length, greaterThan(1000));
    expect(questions.where((q) => !chapters.contains(q.chapterId)), isEmpty);
    expect(questions.where((q) => !topics.contains(q.topicId)).length, lessThan(questions.length ~/ 20));
  }, skip: !live, timeout: const Timeout(Duration(minutes: 2)));

  test('student progress loads from mastery, chapter progress, activity and attempts', () async {
    final token = await student();
    final data = await RemoteProgress(client(token), 'u-student-1').load();
    expect(data.topics, isNotEmpty);
    expect(data.activities, isNotEmpty);
    expect(data.attempts, isNotEmpty);
  }, skip: !live);

  test('a question bookmark can be added and removed on the server', () async {
    final remote = RemoteProgress(client(await student()), 'u-student-1');
    final before = await remote.questionBookmarks();
    final id = await remote.addBookmark('q-phy-001-live', title: 'live test');
    expect((await remote.questionBookmarks())['q-phy-001-live'], id);
    await remote.removeBookmark(id);
    expect((await remote.questionBookmarks()).length, before.length);
  }, skip: !live);

  test("student's decks and cards map onto the app model", () async {
    final api = client(await student());
    final decks = await OwnerSync(api, collection: 'decks', studentId: 'u-student-1').pull();
    final cards = await OwnerSync(api, collection: 'cards', studentId: 'u-student-1').pull();
    expect([for (final d in decks) FlashcardMapper.deckFrom(d)], isNotEmpty);
    final mapped = [for (final c in cards) FlashcardMapper.cardFrom(c)];
    expect(mapped.every((c) => decks.any((d) => d['id'] == c.deckId)), isTrue);
  }, skip: !live);

  test("student's notes and planner tasks map onto the app model and round-trip", () async {
    final api = client(await student());
    final notes = await OwnerSync(api, collection: 'notes', studentId: 'u-student-1').pull();
    final tasks = await OwnerSync(api, collection: 'tasks', studentId: 'u-student-1').pull();
    expect(notes, isNotEmpty);
    expect(tasks, isNotEmpty);
    for (final j in notes) {
      final n = NoteMapper.fromApi(j);
      expect(n.title, j['title']);
      expect(NoteMapper.kindOf(n.type), j['kind'] == 'custom' || j['kind'] == null ? 'custom' : j['kind']);
    }
    for (final j in tasks) {
      final t = TaskMapper.fromApi(j);
      final back = TaskMapper.fields(t);
      expect(back['date'], (j['date'] as String).substring(0, 10));
      expect(back['durationMinutes'], j['durationMinutes']);
    }
  }, skip: !live);

  test('exams and attempts map; a model test starts with known questions and is discarded', () async {
    final remote = RemoteExams(client(await student()), 'u-student-1');
    final exams = await remote.exams();
    final byId = {for (final e in exams) e['id'] as String: e};
    final offered = [for (final e in exams) if (RemoteExams.isOffered(e)) RemoteExams.templateFrom(e)];
    expect(offered, isNotEmpty);
    final attempts = await remote.attempts();
    final resumable = {for (final a in attempts) if (a['status'] == 'in_progress') a['id']};
    for (final a in attempts) {
      final m = RemoteExams.attemptFrom(a, exams: byId);
      if (m.status.name != 'inProgress') expect(m.result, isNotNull);
    }
    final model = offered.firstWhere((t) => byId[t.id]!['kind'] == 'model_test' && t.scheduledAt == null);
    final id = await remote.startExam(model.id);
    try {
      final qs = await remote.questions(id);
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.subjectId.isNotEmpty), isTrue);
    } finally {
      // Starting resumes an open attempt; only discard one this test created.
      if (!resumable.contains(id)) await remote.discard(id);
    }
  }, skip: !live);

  test("student's tutor conversations, messages and folders map onto the app model", () async {
    final data = await RemoteTutor(client(await student()), 'u-student-1').load();
    expect(data.conversations, isNotEmpty);
    expect(data.folders, isNotEmpty);
    final messages = [for (final c in data.conversations) ...c.messages];
    expect(messages.where((m) => m.isUser), isNotEmpty);
    expect(messages.where((m) => !m.isUser && m.sources.isNotEmpty), isNotEmpty);
    expect(data.conversations.any((c) => c.folder != null), isTrue);
  }, skip: !live);

  test('guardian portal: links, child summaries, feedback and goals map from the server', () async {
    final s = await ApiAuthRepository(client()).login(identifier: 'parent@shikkha.ai', password: 'demo-password-123');
    final remote = RemoteGuardian(client(s.accessToken), s.user.id);
    final links = await remote.links();
    final children = await remote.children();
    expect(links, isNotEmpty);
    for (final l in links.where((l) => l['status'] == 'active')) {
      final summary = children.firstWhere((c) => (c['link'] as Map)['id'] == l['id']);
      final child = await remote.childSummary(RemoteGuardian.linkFrom(l), l['studentId'] as String, summary);
      expect(child.subjectMastery.length, (summary['subjectMastery'] as List).length);
    }
    final feedback = await remote.feedback();
    expect(feedback, isNotEmpty);
    expect(await remote.goals(), isNotEmpty);
  }, skip: !live);

  test('teacher portal: classes, assignments, answer scripts and feedback map from the server', () async {
    final s = await ApiAuthRepository(client()).login(identifier: 'teacher@shikkha.ai', password: 'demo-password-123');
    final snap = await RemoteTeacher(client(s.accessToken), teacherId: s.user.id, teacherName: s.user.name).load();
    expect(snap.classes, isNotEmpty);
    expect(snap.classes.every((c) => c.students.isNotEmpty), isTrue);
    expect(snap.state.assignments, isNotEmpty);
    expect(snap.studentIds, isNotEmpty);
    expect(snap.state.submissions.every((x) => snap.evaluationOwners.containsKey(x.id)), isTrue);
    final review = RemoteReview(client(s.accessToken));
    expect(await review.items(), isNotEmpty);
    expect((await review.rubrics()).every((r) => r.criteria.isNotEmpty), isTrue);
  }, skip: !live);

  test("student's profile and privacy map from the server", () async {
    final j = await RemoteProfile(client(await student()), 'u-student-1').load();
    expect(j, isNotNull);
    final p = RemoteProfile.fromApi(j!, const StudentProfile());
    expect(p.name, isNotEmpty);
    expect(p.onboarded, isTrue);
    expect(RemoteProfile.privacyFrom(j).keys, containsAll(['progress', 'scores', 'conversations', 'leaderboard']));
  }, skip: !live);

  test('English progress document and server gamification map onto the app', () async {
    final api = client(await student());
    final doc = (await api.get('/documents/english:u-student-1', parse: (d) => (d! as Map).cast<String, dynamic>())).data;
    expect(EnglishDoc.fromDoc(doc).scores, isNotEmpty);
    final g = ServerGamification.fromJson((await api.get('/progress/u-student-1/gamification', parse: (d) => (d! as Map).cast<String, dynamic>())).data);
    expect(g.xp, greaterThan(0));
    expect(g.badges, isNotEmpty);
  }, skip: !live);

  test("student's book reading state maps onto the library", () async {
    final records = await OwnerSync(client(await student()), collection: 'reading', studentId: 'u-student-1').pull();
    expect(records, isNotEmpty);
    for (final j in records) {
      final r = ReadingMapper.fromApi(j, null);
      expect(r.bookId, startsWith('book-'));
      expect(ReadingMapper.serverBookId(r.bookId), j['bookId']);
    }
  }, skip: !live);

  test('book avatar: session, book-grounded answer, feedback and history on the server', () async {
    final remote = RemoteAvatar(client(await student()), 'u-student-1');
    final (session, greeting) = await remote.startSession('book-ssc-physics');
    expect(session.bookId, 'book-ssc-physics');
    expect(greeting.grounded, Grounding.greeting);
    final (question, reply) = await remote.ask(session.id, 'ত্বরণ কাকে বলে?');
    expect(question.role, AvatarRole.student);
    expect(reply.grounded, Grounding.book);
    expect(reply.citations, isNotEmpty);
    expect((await remote.feedback(reply.id, 'up')).feedback, 'up');
    final (sessions, messages) = await remote.history();
    expect(sessions.any((s) => s.id == session.id), isTrue);
    expect(messages.where((m) => m.sessionId == session.id).length, 3);
    expect((await remote.avatars()).any((a) => a.bookId == 'book-ssc-physics'), isTrue);
    expect(await remote.usage('u-student-1'), isNotEmpty);
  }, skip: !live);

  test('paper archive: server board/institution papers; a saved paper is a web bookmark', () async {
    final remote = RemoteArchive(client(await student()), 'u-student-1');
    await remote.loadCatalog();
    addTearDown(ArchiveCatalog.clear);
    final dhaka = ArchiveCatalog.boardPapers('ssc-physics', 'dhaka', 2023);
    expect(dhaka, isNotEmpty);
    expect(ArchiveCatalog.institutionPapers, isNotEmpty);
    expect(ArchiveCatalog.institutions, isNotEmpty);
    final appId = ArchiveCatalog.appPaperId(dhaka.first['id'] as String);
    expect(appId, 'bp-dhaka-2023-ssc-physics');
    final paper = ArchivePaper(id: appId, title: const Tr.same('live'), subject: subjectById('ssc-phy')!, year: 2023, questionIds: const [], boardId: 'dhaka');
    final id = (await remote.save(paper))!;
    expect((await remote.savedPapers())[appId], id);
    await remote.unsave(id);
    expect((await remote.savedPapers()).containsKey(appId), isFalse);
  }, skip: !live);

  test("student's practice sets map onto the app", () async {
    final records = await OwnerSync(client(await student()), collection: 'practice-sets', studentId: 'u-student-1').pull();
    expect(records, isNotEmpty);
    final set = PracticeSet.fromApi(records.first);
    expect(set.name, isNotEmpty);
    expect(set.questionIds, isNotEmpty);
  }, skip: !live);

  test("student's study-plan settings document maps onto the planner", () async {
    final doc = (await client(await student()).get('/documents/planSettings:u-student-1', parse: (d) => (d! as Map).cast<String, dynamic>())).data;
    final prefs = PlanSettingsMapper.fromApi(doc, PlannerPrefs(examDate: DateTime(2000)));
    expect(prefs.examDate.year, greaterThan(2025));
    expect(prefs.dailyMinutes, doc['dailyMinutes']);
  }, skip: !live);
}
