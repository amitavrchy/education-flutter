import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shikkhaai_mobile/features/book_avatar/application/avatar_voice.dart';

import '../../helpers/fake_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bangla speech is fetched from the server (cached per text and voice)', () async {
    final server = FakeServer();
    server.responses['POST /speech'] = {'mediaType': 'audio/wav', 'data': 'UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAIA+AAACABAAZGF0YQAAAAA=', 'simulated': false};
    final voice = ServerSpeechAvatarVoice(server.client, player: _NoPlayer());
    voice.gender = 'male';
    await voice.speak('আসসালামু আলাইকুম', lang: 'bn');
    await voice.speak('আসসালামু আলাইকুম', lang: 'bn');
    expect(server.calls.where((c) => c == 'POST /speech').length, 1);
    expect(server.lastBody['/speech'], {'text': 'আসসালামু আলাইকুম', 'language': 'bn', 'voice': 'male'});
  });
}

/// Completes playback immediately (no audio device in tests).
class _NoPlayer extends Fake implements AudioPlayer {
  final _done = StreamController<void>.broadcast();

  @override
  Stream<void> get onPlayerComplete => _done.stream;

  @override
  Future<void> setPlaybackRate(double playbackRate) async {}

  @override
  Future<void> play(Source source, {double? volume, double? balance, AudioContext? ctx, Duration? position, PlayerMode? mode}) async {
    scheduleMicrotask(() => _done.add(null));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
