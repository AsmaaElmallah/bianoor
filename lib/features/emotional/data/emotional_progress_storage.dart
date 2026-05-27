import '../../../core/storage/prefs_service.dart';
import '../../../core/sync/user_progress_sync_service.dart';
import '../../curriculum/domain/curriculum_shared_schedule.dart';
import '../domain/emotional_progress.dart';

class EmotionalProgressStorage {
  EmotionalProgressStorage(this._prefs, [this._sync]);

  final PrefsService _prefs;
  final UserProgressSyncService? _sync;

  EmotionalProgress load() {
    return EmotionalProgress(
      curriculumDay: _prefs.getEmotionalCurriculumDay(),
      roundsCompletedToday: _prefs.getEmotionalRoundsCompletedToday(),
      lastSessionDateIso: _prefs.getEmotionalLastSessionDate(),
      programStartDateIso: _prefs.getEmotionalProgramStartDate(),
    );
  }

  Future<void> save(EmotionalProgress progress) async {
    await _prefs.setEmotionalCurriculumDay(progress.curriculumDay);
    await _prefs.setEmotionalRoundsCompletedToday(progress.roundsCompletedToday);
    if (progress.lastSessionDateIso != null) {
      await _prefs.setEmotionalLastSessionDate(progress.lastSessionDateIso!);
    }
    if (progress.programStartDateIso != null) {
      await _prefs.setEmotionalProgramStartDate(progress.programStartDateIso!);
    }
    await _sync?.pushIfLoggedIn();
  }

  Future<EmotionalProgress> ensureProgramStart() async {
    final current = load();
    if (current.programStartDateIso != null) return current;
    final today = DateTime.now().toIso8601String().split('T').first;
    final updated = current.copyWith(programStartDateIso: today);
    await save(updated);
    return updated;
  }

  int effectiveCurriculumDay(EmotionalProgress progress) {
    if (_prefs.isDevBypassProgramCalendar()) {
      return progress.curriculumDay.clamp(1, curriculumProgramTotalDays);
    }
    return curriculumDayFromStart(progress);
  }

  int curriculumDayFromStart(EmotionalProgress progress) {
    final startIso = progress.programStartDateIso;
    if (startIso == null) return progress.curriculumDay.clamp(1, 9999);
    final start = DateTime.parse(startIso);
    final now = DateTime.now();
    final days = now.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
    return days.clamp(1, 9999);
  }

  bool canStartAnotherRoundToday(EmotionalProgress progress, int dailyRepetitions) {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (progress.lastSessionDateIso != today) return true;
    return progress.roundsCompletedToday < dailyRepetitions;
  }

  Future<EmotionalProgress> completeRound(EmotionalProgress current) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    var roundsToday = current.roundsCompletedToday;
    if (current.lastSessionDateIso != today) {
      roundsToday = 0;
    }
    roundsToday += 1;

    final updated = current.copyWith(
      roundsCompletedToday: roundsToday,
      lastSessionDateIso: today,
    );
    await save(updated);
    return updated;
  }
}
