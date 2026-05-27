import '../../../core/storage/prefs_service.dart';
import '../../../core/sync/user_progress_sync_service.dart';
import '../domain/quran_age_schedule.dart';
import '../domain/quran_progress.dart';

class QuranProgressStorage {
  QuranProgressStorage(this._prefs, [this._sync]);

  final PrefsService _prefs;
  final UserProgressSyncService? _sync;

  QuranProgress load() {
    return QuranProgress(
      currentKhatmahIndex: _prefs.getQuranKhatmahIndex(),
      currentSessionIndex: _prefs.getQuranSessionIndex(),
      completedKhatmahsCount: _prefs.getQuranCompletedKhatmahs(),
      sessionsCompletedToday: _prefs.getQuranSessionsCompletedToday(),
      lastListenDateIso: _prefs.getQuranLastListenDate(),
    );
  }

  Future<void> save(QuranProgress progress) async {
    await _prefs.setQuranKhatmahIndex(progress.currentKhatmahIndex);
    await _prefs.setQuranSessionIndex(progress.currentSessionIndex);
    await _prefs.setQuranCompletedKhatmahs(progress.completedKhatmahsCount);
    await _prefs.setQuranSessionsCompletedToday(progress.sessionsCompletedToday);
    if (progress.lastListenDateIso != null) {
      await _prefs.setQuranLastListenDate(progress.lastListenDateIso!);
    }
    await _sync?.pushIfLoggedIn();
  }

  Future<QuranProgress> completeSession({
    required QuranProgress current,
    required int dailyRepetitions,
    required String todayIso,
  }) async {
    var sessionsToday = current.sessionsCompletedToday;
    if (current.lastListenDateIso != todayIso) {
      sessionsToday = 0;
    }
    sessionsToday += 1;

    var khatmahIndex = current.currentKhatmahIndex;
    var sessionIndex = current.currentSessionIndex;
    var completedKhatmahs = current.completedKhatmahsCount;

    if (sessionIndex >= quranSessionsPerKhatmah) {
      completedKhatmahs += 1;
      khatmahIndex = (khatmahIndex + 1).clamp(1, quranTargetKhatmahCount);
      sessionIndex = 1;
    } else {
      sessionIndex += 1;
    }

    final updated = current.copyWith(
      currentKhatmahIndex: khatmahIndex,
      currentSessionIndex: sessionIndex,
      completedKhatmahsCount: completedKhatmahs,
      sessionsCompletedToday: sessionsToday,
      lastListenDateIso: todayIso,
    );
    await save(updated);
    return updated;
  }

  bool canStartAnotherSessionToday(QuranProgress progress, int dailyRepetitions) {
    if (progress.lastListenDateIso == null) return true;
    final today = DateTime.now().toIso8601String().split('T').first;
    if (progress.lastListenDateIso != today) return true;
    return progress.sessionsCompletedToday < dailyRepetitions;
  }
}
