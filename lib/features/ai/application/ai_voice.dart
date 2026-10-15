import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// On-device voice (free): speech-to-text for questions, text-to-speech for answers.
class AiVoice {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttReady = false;
  bool _ttsReady = false;
  String? _localeId;
  VoidCallback? _onListenDone;
  int _speakRun = 0;

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
        const preferred = ['ar_EG', 'ar-EG', 'ar_YE', 'ar-YE', 'ar_SA', 'ar-SA'];
        _localeId = preferred.where(ids.contains).firstOrNull ??
            ids.where((id) => id.startsWith('ar')).firstOrNull;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AI voice] stt init failed: $e');
      _sttReady = false;
    }
    return _sttReady;
  }

  /// Picks the most natural Arabic voice installed: Google's online («network») voices sound far
  /// less robotic than the default offline one.
  Future<void> _initTts() async {
    if (_ttsReady) return;
    _ttsReady = true;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.05);
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (_) {}
    try {
      final voices = await _tts.getVoices;
      final arabic = [
        if (voices is List)
          for (final v in voices)
            if (v is Map && '${v['locale']}'.toLowerCase().startsWith('ar')) Map<String, String>.from(
              v.map((k, val) => MapEntry('$k', '$val')),
            ),
      ];
      int score(Map<String, String> v) {
        final name = (v['name'] ?? '').toLowerCase();
        final locale = (v['locale'] ?? '').toLowerCase();
        var s = 0;
        if (name.contains('network') || name.contains('neural') || name.contains('enhanced')) s += 4;
        if (locale.contains('eg')) s += 2;
        if (locale.contains('sa') || locale.contains('xa')) s += 1;
        if (name.contains('local')) s -= 1;
        return s;
      }

      arabic.sort((a, b) => score(b).compareTo(score(a)));
      if (arabic.isNotEmpty) {
        await _tts.setVoice({'name': arabic.first['name']!, 'locale': arabic.first['locale']!});
        if (kDebugMode) debugPrint('[AI voice] using ${arabic.first}');
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AI voice] voice list failed: $e');
    }
    await _tts.setLanguage('ar');
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

  /// Reads the answer sentence by sentence (long texts get cut off by some engines).
  Future<void> speak(String text, {VoidCallback? onDone}) async {
    await stopListening();
    await _tts.stop();
    await _initTts();
    final run = ++_speakRun;
    for (final sentence in speechChunks(text)) {
      if (run != _speakRun) return;
      await _tts.speak(sentence);
    }
    if (run == _speakRun) onDone?.call();
  }

  Future<void> stopSpeaking() async {
    _speakRun++;
    await _tts.stop();
  }

  void dispose() {
    _onListenDone = null;
    _speakRun++;
    _stt.cancel();
    _tts.stop();
  }
}

/// Markdown, emojis and links read aloud sound broken — keep only the words.
@visibleForTesting
List<String> speechChunks(String text) {
  final clean = text
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '')
      .replaceAllMapped(RegExp(r'^\s*(\d+)[.)]\s+', multiLine: true), (m) => '${m[1]}، ')
      .replaceAll(RegExp(r'[*_`~>|]'), '')
      .replaceAll(RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]', unicode: true), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ');
  final chunks = <String>[];
  for (final line in clean.split('\n')) {
    for (final part in line.split(RegExp(r'(?<=[.!?؟।])\s+'))) {
      final s = part.trim();
      if (s.length > 1) chunks.add(s);
    }
  }
  return chunks;
}
