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
}

/// Provider that must be overridden in main() with an initialized instance.
final prefsServiceProvider = Provider<PrefsService>((ref) {
  throw UnimplementedError(
    'prefsServiceProvider must be overridden in main() before runApp().',
  );
});
