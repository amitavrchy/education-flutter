import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voice I/O for the avatar teacher: device text-to-speech for answers and speech-to-text for
/// questions. The API only exchanges text, so a server TTS/STT can replace this later.
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
  final voice = DeviceAvatarVoice();
  ref.onDispose(voice.dispose);
  return voice;
});
