import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around SharedPreferences with typed accessors used across the app.
class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kVideoIndex = 'onboarding_video_index';
  static const _kLanguage = 'app_language';
  static const _kIsOnboardingComplete = 'is_onboarding_complete';
  static const _kIsAuthenticated = 'is_authenticated';
  static const _kBabyName = 'baby_name';
  static const _kBabyAgeRangeIndex = 'baby_age_range_index';
  static const _kRulesAccepted = 'rules_accepted';
  static const _kQuranKhatmahIndex = 'quran_current_khatmah_index';
  static const _kQuranSessionIndex = 'quran_current_session_index';
  static const _kQuranCompletedKhatmahs = 'quran_completed_khatmahs_count';
  static const _kQuranSessionsToday = 'quran_sessions_completed_today';
  static const _kQuranLastListenDate = 'quran_last_listen_date';
  static const _kMathCurriculumDay = 'math_curriculum_day';
  static const _kMathRoundsToday = 'math_rounds_completed_today';
  static const _kMathLastSessionDate = 'math_last_session_date';
  static const _kMathProgramStartDate = 'math_program_start_date';
  static const _kVisualCurriculumDay = 'visual_curriculum_day';
  static const _kVisualRoundsToday = 'visual_rounds_completed_today';
  static const _kVisualLastSessionDate = 'visual_last_session_date';
  static const _kVisualProgramStartDate = 'visual_program_start_date';
  static const _kEmotionalCurriculumDay = 'emotional_curriculum_day';
  static const _kEmotionalRoundsToday = 'emotional_rounds_completed_today';
  static const _kEmotionalLastSessionDate = 'emotional_last_session_date';
  static const _kEmotionalProgramStartDate = 'emotional_program_start_date';
  static const _kAptitudeTestAnswers = 'aptitude_test_0_2_answers';

  int getVideoIndex() => _prefs.getInt(_kVideoIndex) ?? 0;
  Future<void> setVideoIndex(int value) => _prefs.setInt(_kVideoIndex, value);

  String? getLanguage() => _prefs.getString(_kLanguage);
  Future<void> setLanguage(String code) => _prefs.setString(_kLanguage, code);

  bool isOnboardingComplete() => _prefs.getBool(_kIsOnboardingComplete) ?? false;
  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_kIsOnboardingComplete, value);

  bool isAuthenticated() => _prefs.getBool(_kIsAuthenticated) ?? false;
  Future<void> setAuthenticated(bool value) =>
      _prefs.setBool(_kIsAuthenticated, value);

  String? getBabyName() => _prefs.getString(_kBabyName);
  Future<void> setBabyName(String name) => _prefs.setString(_kBabyName, name);

  int getBabyAgeRangeIndex() => _prefs.getInt(_kBabyAgeRangeIndex) ?? 0;
  Future<void> setBabyAgeRangeIndex(int index) =>
      _prefs.setInt(_kBabyAgeRangeIndex, index);

  bool getRulesAccepted() => _prefs.getBool(_kRulesAccepted) ?? false;
  Future<void> setRulesAccepted(bool value) =>
      _prefs.setBool(_kRulesAccepted, value);

  int getQuranKhatmahIndex() => _prefs.getInt(_kQuranKhatmahIndex) ?? 1;
  Future<void> setQuranKhatmahIndex(int value) =>
      _prefs.setInt(_kQuranKhatmahIndex, value);

  int getQuranSessionIndex() => _prefs.getInt(_kQuranSessionIndex) ?? 1;
  Future<void> setQuranSessionIndex(int value) =>
      _prefs.setInt(_kQuranSessionIndex, value);

  int getQuranCompletedKhatmahs() =>
      _prefs.getInt(_kQuranCompletedKhatmahs) ?? 0;
  Future<void> setQuranCompletedKhatmahs(int value) =>
      _prefs.setInt(_kQuranCompletedKhatmahs, value);

  int getQuranSessionsCompletedToday() =>
      _prefs.getInt(_kQuranSessionsToday) ?? 0;
  Future<void> setQuranSessionsCompletedToday(int value) =>
      _prefs.setInt(_kQuranSessionsToday, value);

  String? getQuranLastListenDate() => _prefs.getString(_kQuranLastListenDate);
  Future<void> setQuranLastListenDate(String value) =>
      _prefs.setString(_kQuranLastListenDate, value);

  int getMathCurriculumDay() => _prefs.getInt(_kMathCurriculumDay) ?? 1;
  Future<void> setMathCurriculumDay(int value) =>
      _prefs.setInt(_kMathCurriculumDay, value);

  int getMathRoundsCompletedToday() => _prefs.getInt(_kMathRoundsToday) ?? 0;
  Future<void> setMathRoundsCompletedToday(int value) =>
      _prefs.setInt(_kMathRoundsToday, value);

  String? getMathLastSessionDate() => _prefs.getString(_kMathLastSessionDate);
  Future<void> setMathLastSessionDate(String value) =>
      _prefs.setString(_kMathLastSessionDate, value);

  String? getMathProgramStartDate() => _prefs.getString(_kMathProgramStartDate);
  Future<void> setMathProgramStartDate(String value) =>
      _prefs.setString(_kMathProgramStartDate, value);

  int getVisualCurriculumDay() => _prefs.getInt(_kVisualCurriculumDay) ?? 1;
  Future<void> setVisualCurriculumDay(int value) =>
      _prefs.setInt(_kVisualCurriculumDay, value);

  int getVisualRoundsCompletedToday() => _prefs.getInt(_kVisualRoundsToday) ?? 0;
  Future<void> setVisualRoundsCompletedToday(int value) =>
      _prefs.setInt(_kVisualRoundsToday, value);

  String? getVisualLastSessionDate() => _prefs.getString(_kVisualLastSessionDate);
  Future<void> setVisualLastSessionDate(String value) =>
      _prefs.setString(_kVisualLastSessionDate, value);

  String? getVisualProgramStartDate() => _prefs.getString(_kVisualProgramStartDate);
  Future<void> setVisualProgramStartDate(String value) =>
      _prefs.setString(_kVisualProgramStartDate, value);

  int getEmotionalCurriculumDay() => _prefs.getInt(_kEmotionalCurriculumDay) ?? 1;
  Future<void> setEmotionalCurriculumDay(int value) =>
      _prefs.setInt(_kEmotionalCurriculumDay, value);

  int getEmotionalRoundsCompletedToday() => _prefs.getInt(_kEmotionalRoundsToday) ?? 0;
  Future<void> setEmotionalRoundsCompletedToday(int value) =>
      _prefs.setInt(_kEmotionalRoundsToday, value);

  String? getEmotionalLastSessionDate() => _prefs.getString(_kEmotionalLastSessionDate);
  Future<void> setEmotionalLastSessionDate(String value) =>
      _prefs.setString(_kEmotionalLastSessionDate, value);

  String? getEmotionalProgramStartDate() => _prefs.getString(_kEmotionalProgramStartDate);
  Future<void> setEmotionalProgramStartDate(String value) =>
      _prefs.setString(_kEmotionalProgramStartDate, value);

  /// إجابات اختبار القدرات (0–2): معرّف السؤال → true نعم / false لا.
  Map<String, bool>? getAptitudeTestAnswers() {
    final raw = _prefs.getString(_kAptitudeTestAnswers);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, value == true),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setAptitudeTestAnswers(Map<String, bool?> answers) async {
    final toStore = <String, bool>{};
    for (final entry in answers.entries) {
      final value = entry.value;
      if (value != null) toStore[entry.key] = value;
    }
    await _prefs.setString(_kAptitudeTestAnswers, jsonEncode(toStore));
  }

  /// إجابات اختبارات الأم (مهارات / ميول): مفتاح التخزين → إجابات.
  Map<String, bool>? getMotherQuizAnswers(String storageKey) {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, value == true),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setMotherQuizAnswers(
    String storageKey,
    Map<String, bool?> answers,
  ) async {
    final toStore = <String, bool>{};
    for (final entry in answers.entries) {
      final value = entry.value;
      if (value != null) toStore[entry.key] = value;
    }
    await _prefs.setString(storageKey, jsonEncode(toStore));
  }

  /// سجل JSON (شكاوى / اقتراحات محلية).
  List<Map<String, dynamic>>? getJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
  }
}

/// Provider that must be overridden in main() with an initialized instance.
final prefsServiceProvider = Provider<PrefsService>((ref) {
  throw UnimplementedError(
    'prefsServiceProvider must be overridden in main() before runApp().',
  );
});
