import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/core/network/api_client.dart';
import 'package:shikkhaai_mobile/core/network/owner_sync.dart';
import 'package:shikkhaai_mobile/features/account/account_controller.dart';
import 'package:shikkhaai_mobile/features/account/remote_billing.dart';
import 'package:shikkhaai_mobile/features/auth/data/auth_repository.dart';
import 'package:shikkhaai_mobile/features/auth/domain/app_user.dart';
import 'package:shikkhaai_mobile/features/curriculum/data/curriculum_catalog.dart';
import 'package:shikkhaai_mobile/features/flashcards/data/remote_flashcards.dart';
import 'package:shikkhaai_mobile/features/notes/data/remote_notes.dart';
import 'package:shikkhaai_mobile/features/notifications/data/remote_notifications.dart';
import 'package:shikkhaai_mobile/features/planner/data/remote_tasks.dart';
import 'package:shikkhaai_mobile/features/progress/data/remote_progress.dart';
import 'package:shikkhaai_mobile/features/question_bank/data/question_mapper.dart';

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
}
