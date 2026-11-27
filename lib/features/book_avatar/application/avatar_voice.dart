import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

/// Voice I/O for the avatar teacher (also the voice tutor, audio lessons and English coach):
/// text-to-speech for answers and device speech-to-text for questions. In API mode Bangla speech
/// comes from the server (see [ServerSpeechAvatarVoice]).
abstract class AvatarVoice {
  /// Speaks [text]; completes when speech ends. [onWord] fires on word boundaries (lip-sync).
  /// Returns false when the device cannot speak this language (the avatar then lip-syncs
  /// silently over the caption).
  Future<bool> speak(String text, {required String lang, double rate = 1, double pitch = 1, VoidCallback? onWord});

  Future<void> stopSpeaking();

  /// Whether speech recognition is available on this device.
  Future<bool> canListen();

  /// Starts listening; [onResult] receives partial and final transcripts.
  /// Returns false when the microphone is unavailable or permission was denied.
  Future<bool> listen({required String lang, required void Function(String words, bool isFinal) onResult, VoidCallback? onDone});

  Future<void> stopListening();

  /// Multiplier for simulated speech time when the device cannot speak (0 = instant, for tests).
  double get simulationScale => 1;

  void dispose() {}
}

/// Device implementation (flutter_tts + speech_to_text).
class DeviceAvatarVoice extends AvatarVoice {
  final _tts = FlutterTts();
  final _stt = SpeechToText();
  bool? _sttReady;
  Completer<void>? _speaking;
  VoidCallback? _onWord;
  VoidCallback? _onListenDone;

  DeviceAvatarVoice() {
    void finish() {
      final c = _speaking;
      _speaking = null;
      if (c != null && !c.isCompleted) c.complete();
    }

    _tts.setCompletionHandler(finish);
    _tts.setCancelHandler(finish);
    _tts.setErrorHandler((_) => finish());
    _tts.setProgressHandler((text, start, end, word) => _onWord?.call());
  }

  @override
  Future<bool> speak(String text, {required String lang, double rate = 1, double pitch = 1, VoidCallback? onWord}) async {
    await stopSpeaking();
    try {
      final locale = lang == 'en' ? 'en-US' : 'bn-BD';
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true) return false;
      await _tts.setLanguage(locale);
      // flutter_tts: 0.5 ≈ normal speed on Android/iOS.
      await _tts.setSpeechRate((0.5 * rate).clamp(0.1, 1.0));
      await _tts.setPitch(pitch.clamp(0.5, 2.0));
      _onWord = onWord;
      final done = _speaking = Completer<void>();
      await _tts.speak(text);
      await done.future;
      return true;
    } on Object {
      return false;
    } finally {
      _onWord = null;
    }
  }

  @override
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } on Object {
      // Ignore: nothing was speaking.
    }
    final c = _speaking;
    _speaking = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<bool> canListen() async {
    try {
      return _sttReady ??= await _stt.initialize(
        onStatus: (status) {
          if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) _onListenDone?.call();
        },
        onError: (_) => _onListenDone?.call(),
      );
    } on Object {
      return _sttReady = false;
    }
  }

  @override
  Future<bool> listen({required String lang, required void Function(String words, bool isFinal) onResult, VoidCallback? onDone}) async {
    if (!await canListen()) return false;
    _onListenDone = onDone;
    try {
      await _stt.listen(
        onResult: (r) => onResult(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(partialResults: true, localeId: lang == 'en' ? 'en_US' : 'bn_BD', listenMode: ListenMode.dictation),
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } on Object {
      // Ignore.
    }
  }

  @override
  void dispose() {
    unawaited(stopSpeaking());
    unawaited(stopListening());
  }
}

/// No audio: used in tests and as the explicit "muted" fallback. Speech takes no time;
/// recognition is unavailable (the classroom then offers sample voice questions).
class SilentAvatarVoice extends AvatarVoice {
  @override
  Future<bool> speak(String text, {required String lang, double rate = 1, double pitch = 1, VoidCallback? onWord}) async => false;

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<bool> canListen() async => false;

  @override
  Future<bool> listen({required String lang, required void Function(String words, bool isFinal) onResult, VoidCallback? onDone}) async => false;

  @override
  Future<void> stopListening() async {}

  @override
  double get simulationScale => 0;
}

final avatarVoiceProvider = Provider<AvatarVoice>((ref) {
  final voice = Env.useMockApi ? DeviceAvatarVoice() : ServerSpeechAvatarVoice(ref.watch(apiClientProvider));
  ref.onDispose(voice.dispose);
  return voice;
});

/// API mode: Bangla (and any language the phone has no voice for) is spoken with server-made
/// speech (`POST /speech`, education-ai Gemini TTS); everything else uses the device voice.
/// Lip-sync gets a steady word rhythm while the audio plays.
class ServerSpeechAvatarVoice extends DeviceAvatarVoice {
  ServerSpeechAvatarVoice(this._api, {AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final ApiClient _api;
  final AudioPlayer _player;
  final Map<String, Uint8List> _cache = {};
  int _turn = 0;
  Timer? _rhythm;

  /// Female or male teacher voice for the next utterances (the avatar's look decides).
  String gender = 'female';

  Future<Uint8List> _audio(String text, String lang) async {
    final key = '$gender|$lang|$text';
    final hit = _cache[key];
    if (hit != null) return hit;
    final res = await _api.post('/speech', body: {'text': text.length > 2500 ? text.substring(0, 2500) : text, 'language': lang, 'voice': gender}, parse: (d) => (d! as Map).cast<String, dynamic>());
    final bytes = base64Decode(res.data['data'] as String);
    if (_cache.length >= 30) _cache.remove(_cache.keys.first);
    return _cache[key] = bytes;
  }

  @override
  Future<bool> speak(String text, {required String lang, double rate = 1, double pitch = 1, VoidCallback? onWord}) async {
    final short = lang == 'en' ? 'en' : 'bn';
    if (short == 'en' && await super.speak(text, lang: lang, rate: rate, pitch: pitch, onWord: onWord)) return true;
    await stopSpeaking();
    final turn = ++_turn;
    try {
      final bytes = await _audio(text, short);
      if (turn != _turn) return true;
      final done = Completer<void>();
      final sub = _player.onPlayerComplete.listen((_) => done.isCompleted ? null : done.complete());
      _rhythm = Timer.periodic(const Duration(milliseconds: 320), (_) => onWord?.call());
      await _player.setPlaybackRate(rate.clamp(0.5, 2.0));
      await _player.play(kIsWeb ? UrlSource('data:audio/wav;base64,${base64Encode(bytes)}') : BytesSource(bytes, mimeType: 'audio/wav'));
      await done.future;
      await sub.cancel();
      return true;
    } on Object {
      return false;
    } finally {
      if (turn == _turn) {
        _rhythm?.cancel();
        _rhythm = null;
      }
    }
  }

  @override
  Future<void> stopSpeaking() async {
    _turn++;
    _rhythm?.cancel();
    _rhythm = null;
    try {
      await _player.stop();
    } on Object {
      // Nothing playing.
    }
    await super.stopSpeaking();
  }

  @override
  void dispose() {
    super.dispose();
    unawaited(_player.dispose());
  }
}
