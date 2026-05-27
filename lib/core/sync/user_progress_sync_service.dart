import 'package:flutter/foundation.dart';

import '../storage/prefs_service.dart';
import '../supabase/supabase_bootstrap.dart';
import 'user_progress_remote_data_source.dart';

/// مزامنة تقدّم الرحلة بين الجهاز و Supabase.
class UserProgressSyncService {
  const UserProgressSyncService(this._prefs, this._remote);

  final PrefsService _prefs;
  final UserProgressRemoteDataSource _remote;

  String? get _userId {
    if (!SupabaseBootstrap.isReady) return null;
    return SupabaseBootstrap.client.auth.currentUser?.id;
  }

  Future<void> pullToDevice(String userId) async {
    if (!SupabaseBootstrap.isEnabled) return;

    try {
      final row = await _remote.fetchForUser(userId);
      if (row == null) {
        await pushFromDevice(userId);
        return;
      }
      await _applyRowToPrefs(row);
      if (kDebugMode) {
        debugPrint('[UserProgressSync] pulled progress for $userId');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[UserProgressSync] pull failed: $e\n$st');
      }
    }
  }

  Future<void> pushIfLoggedIn() async {
    final userId = _userId;
    if (userId == null) return;
    await pushFromDevice(userId);
  }

  Future<void> pushFromDevice(String userId) async {
    if (!SupabaseBootstrap.isEnabled || !SupabaseBootstrap.isReady) return;

    try {
      await _remote.upsert(_prefsToRow(userId));
      if (kDebugMode) {
        debugPrint('[UserProgressSync] pushed progress for $userId');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[UserProgressSync] push failed: $e\n$st');
      }
    }
  }

  Future<void> _applyRowToPrefs(Map<String, dynamic> row) async {
    final babyName = row['baby_name'] as String?;
    if (babyName != null && babyName.isNotEmpty) {
      await _prefs.setBabyName(babyName);
    }

    final ageIndex = row['baby_age_range_index'] as int?;
    if (ageIndex != null) {
      await _prefs.setBabyAgeRangeIndex(ageIndex);
    }

    await _prefs.setMathCurriculumDay(row['math_curriculum_day'] as int? ?? 1);
    await _prefs.setMathRoundsCompletedToday(row['math_rounds_today'] as int? ?? 0);
    final mathLast = row['math_last_session_date'] as String?;
    if (mathLast != null) await _prefs.setMathLastSessionDate(mathLast);
    final mathStart = row['math_program_start_date'] as String?;
    if (mathStart != null) await _prefs.setMathProgramStartDate(mathStart);

    await _prefs.setVisualCurriculumDay(row['visual_curriculum_day'] as int? ?? 1);
    await _prefs.setVisualRoundsCompletedToday(row['visual_rounds_today'] as int? ?? 0);
    final visualLast = row['visual_last_session_date'] as String?;
    if (visualLast != null) await _prefs.setVisualLastSessionDate(visualLast);
    final visualStart = row['visual_program_start_date'] as String?;
    if (visualStart != null) await _prefs.setVisualProgramStartDate(visualStart);

    await _prefs.setEmotionalCurriculumDay(row['emotional_curriculum_day'] as int? ?? 1);
    await _prefs.setEmotionalRoundsCompletedToday(row['emotional_rounds_today'] as int? ?? 0);
    final emotionalLast = row['emotional_last_session_date'] as String?;
    if (emotionalLast != null) await _prefs.setEmotionalLastSessionDate(emotionalLast);
    final emotionalStart = row['emotional_program_start_date'] as String?;
    if (emotionalStart != null) {
      await _prefs.setEmotionalProgramStartDate(emotionalStart);
    }

    await _prefs.setQuranKhatmahIndex(row['quran_khatmah_index'] as int? ?? 1);
    await _prefs.setQuranSessionIndex(row['quran_session_index'] as int? ?? 1);
    await _prefs.setQuranCompletedKhatmahs(row['quran_completed_khatmahs'] as int? ?? 0);
    await _prefs.setQuranSessionsCompletedToday(row['quran_sessions_today'] as int? ?? 0);
    final quranLast = row['quran_last_listen_date'] as String?;
    if (quranLast != null) await _prefs.setQuranLastListenDate(quranLast);

    await _prefs.setDevBypassProgramCalendar(
      row['dev_bypass_program_calendar'] as bool? ?? false,
    );
    await _prefs.setDevUnlockAllLessons(
      row['dev_unlock_all_lessons'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _prefsToRow(String userId) {
    return {
      'user_id': userId,
      'baby_name': _prefs.getBabyName(),
      'baby_age_range_index': _prefs.getBabyAgeRangeIndex(),
      'math_curriculum_day': _prefs.getMathCurriculumDay(),
      'math_rounds_today': _prefs.getMathRoundsCompletedToday(),
      'math_last_session_date': _prefs.getMathLastSessionDate(),
      'math_program_start_date': _prefs.getMathProgramStartDate(),
      'visual_curriculum_day': _prefs.getVisualCurriculumDay(),
      'visual_rounds_today': _prefs.getVisualRoundsCompletedToday(),
      'visual_last_session_date': _prefs.getVisualLastSessionDate(),
      'visual_program_start_date': _prefs.getVisualProgramStartDate(),
      'emotional_curriculum_day': _prefs.getEmotionalCurriculumDay(),
      'emotional_rounds_today': _prefs.getEmotionalRoundsCompletedToday(),
      'emotional_last_session_date': _prefs.getEmotionalLastSessionDate(),
      'emotional_program_start_date': _prefs.getEmotionalProgramStartDate(),
      'quran_khatmah_index': _prefs.getQuranKhatmahIndex(),
      'quran_session_index': _prefs.getQuranSessionIndex(),
      'quran_completed_khatmahs': _prefs.getQuranCompletedKhatmahs(),
      'quran_sessions_today': _prefs.getQuranSessionsCompletedToday(),
      'quran_last_listen_date': _prefs.getQuranLastListenDate(),
      'dev_bypass_program_calendar': _prefs.isDevBypassProgramCalendar(),
      'dev_unlock_all_lessons': _prefs.isDevUnlockAllLessons(),
    };
  }
}
