import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_controller.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/book_catalog.dart';
import 'package:shikkhaai_mobile/features/book_avatar/data/remote_avatar.dart';
import 'package:shikkhaai_mobile/features/book_avatar/domain/avatar_models.dart';

import '../../helpers/fake_server.dart';
import '../../helpers/test_app.dart';

Map<String, dynamic> _serverAvatar() => {
  'id': 'av-book-ssc-physics-bn',
  'bookId': 'book-ssc-physics-bn',
  'name': {'bn': 'সাবরিনা আপা', 'en': 'Sabrina Apa'},
  'title': {'bn': 'পদার্থবিজ্ঞান শিক্ষক', 'en': 'Physics teacher'},
  'appearance': {
    'gender': 'female',
    'skinTone': '#E0AC7E',
    'hairStyle': 'side_part',
    'hairColor': '#1F1A17',
    'outfit': 'saree',
    'outfitColor': '#0F766E',
    'accentColor': '#1D4ED8',
    'glasses': true,
    'beard': false,
    'background': '#E6F4F1',
  },
  'voice': {'language': 'bn', 'rate': 1, 'pitch': 1.1},
  'greeting': {'bn': 'আসসালামু আলাইকুম!', 'en': 'Hello!'},
  'persona': {'style': 'friendly', 'answerLength': 'balanced', 'useExamples': true},
  'scopeChapterIds': <String>[],
  'strictBookScope': true,
  'status': 'active',
  'stats': {'sessions': 3, 'questions': 7, 'outOfScope': 1, 'helpful': 2, 'notHelpful': 0},
};

void main() {
  test('server avatars map onto the app (colours, snake_case, book editions) and back', () {
    final a = RemoteAvatar.avatarFrom(_serverAvatar());
    expect(a.bookId, 'book-ssc-physics');
    expect(a.appearance.hairStyle, HairStyle.sidePart);
    expect(a.appearance.skinTone, 0xFFE0AC7E);
    expect(a.stats.questions, 7);
    final back = RemoteAvatar.avatarToApi(a);
    expect(back['bookId'], 'book-ssc-physics-bn');
    expect((back['appearance'] as Map)['hairStyle'], 'side_part');
    expect((back['appearance'] as Map)['skinTone'], '#E0AC7E');
    final m = RemoteAvatar.messageFrom({
      'id': 'am-1',
      'sessionId': 'as-1',
      'role': 'avatar',
      'text': 't',
      'at': '2026-11-26T05:00:00.000Z',
      'grounded': 'out_of_scope',
      'citations': [
        {'page': 8, 'chapterTitle': 'গতি', 'excerpt': 'e'},
      ],
      'followUps': ['f'],
      'inputMode': 'voice',
    });
    expect(m.grounded, Grounding.outOfScope);
    expect(m.voiceInput, isTrue);
    expect(m.citations.single.page, 8);
  });

  test('API mode: sessions, answers, feedback and reports go through /avatar/*', () async {
    final server = FakeServer({
      '/book-avatars': [_serverAvatar()],
      '/avatar-sessions/u-student-1': [],
      '/avatar-messages/u-student-1': [],
    });
    final session = {
      'id': 'as-1',
      'bookId': 'book-ssc-physics-bn',
      'avatarId': 'av-book-ssc-physics-bn',
      'studentId': 'u-student-1',
      'title': 'নতুন সেশন',
      'startedAt': '2026-11-26T05:00:00.000Z',
      'lastAt': '2026-11-26T05:00:00.000Z',
      'messageCount': 0,
      'voiceTurns': 0,
      'minutes': 0,
    };
    Map<String, dynamic> msg(String id, String role, String text) => {
      'id': id,
      'sessionId': 'as-1',
      'role': role,
      'text': text,
      'at': '2026-11-26T05:01:00.000Z',
      'citations': <Object>[],
      'followUps': <String>[],
    };
    server.responses['POST /avatar/u-student-1/sessions'] = {'session': session, 'greeting': msg('am-g', 'avatar', 'আসসালামু আলাইকুম!')};
    server.responses['POST /avatar/u-student-1/sessions/as-1/messages'] = {
      'question': msg('am-q', 'student', 'ত্বরণ কী?'),
      'reply': {...msg('am-r', 'avatar', 'ত্বরণ হলো…'), 'grounded': 'book'},
    };
    server.responses['POST /avatar/u-student-1/messages/am-r/feedback'] = {...msg('am-r', 'avatar', 'ত্বরণ হলো…'), 'feedback': 'up'};
    server.responses['POST /avatar/u-student-1/messages/am-r/report'] = {
      'id': 'ar-1',
      'bookId': 'book-ssc-physics-bn',
      'avatarId': 'av-book-ssc-physics-bn',
      'studentId': 'u-student-1',
      'question': 'ত্বরণ কী?',
      'answer': 'ত্বরণ হলো…',
      'reason': 'একক নেই',
      'status': 'open',
      'createdAt': '2026-11-26T05:02:00.000Z',
    };
    final c = testContainer(overrides: [remoteAvatarProvider.overrideWithValue(RemoteAvatar(server.client, 'u-student-1'))]);
    c.read(avatarControllerProvider);
    final ctl = c.read(avatarControllerProvider.notifier);
    await ctl.refresh();
    expect(c.read(avatarControllerProvider).avatarForBook('book-ssc-physics')?.name.en, 'Sabrina Apa');
    // Books without a server avatar are still available (the server creates the default one).
    expect(c.read(avatarControllerProvider).available.length, sampleBooks.length);

    final s = await ctl.startSession('book-ssc-physics');
    expect(server.lastBody['/avatar/u-student-1/sessions'], {'bookId': 'book-ssc-physics-bn'});
    final reply = await ctl.ask(s.id, 'ত্বরণ কী?', voice: true);
    expect(reply.grounded, Grounding.book);
    expect(server.lastBody['/avatar/u-student-1/sessions/as-1/messages'], {'text': 'ত্বরণ কী?', 'inputMode': 'voice'});
    final thread = c.read(avatarControllerProvider).messagesOf('as-1');
    expect([for (final m in thread) m.id], ['am-g', 'am-q', 'am-r']);
    expect(c.read(avatarControllerProvider).session('as-1')!.messageCount, 2);

    await ctl.feedback('am-r', 'up');
    expect(c.read(avatarControllerProvider).messagesOf('as-1').last.feedback, 'up');
    await ctl.report('am-r', 'একক নেই');
    expect(c.read(avatarControllerProvider).reports.single.reason, 'একক নেই');
    expect(server.calls.where((x) => x.startsWith('PUT') || x.contains('book-avatars/')), isEmpty); // no client-side counters
  });
}
