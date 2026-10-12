import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// On-device voice (free): speech-to-text for questions, text-to-speech for answers.
class AiVoice {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttReady = false;
  String? _localeId;
  VoidCallback? _onListenDone;

  bool get isListening => _stt.isListening;

  Future<bool> _initStt() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') _onListenDone?.call();
        },
        onError: (_) => _onListenDone?.call(),
      );
      if (_sttReady) {
        final ids = (await _stt.locales()).map((l) => l.localeId).toList();
        const preferred = ['ar_YE', 'ar-YE', 'ar_SA', 'ar-SA', 'ar_EG', 'ar-EG'];
        _localeId = preferred.where(ids.contains).firstOrNull ??
            ids.where((id) => id.startsWith('ar')).firstOrNull;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AI voice] stt init failed: $e');
      _sttReady = false;
    }
    return _sttReady;
  }

  /// Returns false when the microphone / recognition is not available.
  Future<bool> startListening({
    required void Function(String text) onText,
    required VoidCallback onDone,
  }) async {
    await stopSpeaking();
    if (!await _initStt()) return false;
    _onListenDone = onDone;
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) => onText(r.recognizedWords),
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
    return true;
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  Future<void> speak(String text, {VoidCallback? onDone}) async {
    await stopListening();
    await _tts.stop();
    _tts.setCompletionHandler(() => onDone?.call());
    _tts.setCancelHandler(() => onDone?.call());
    await _tts.setLanguage('ar');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  void dispose() {
    _onListenDone = null;
    _stt.cancel();
    _tts.stop();
  }
}