import '../../../core/storage/prefs_service.dart';
import '../domain/visual_progress.dart';

class VisualProgressStorage {
  VisualProgressStorage(this._prefs);

  final PrefsService _prefs;

  VisualProgress load() {
    return VisualProgress(
      curriculumDay: _prefs.getVisualCurriculumDay(),
      roundsCompletedToday: _prefs.getVisualRoundsCompletedToday(),
      lastSessionDateIso: _prefs.getVisualLastSessionDate(),
      programStartDateIso: _prefs.getVisualProgramStartDate(),
    );
  }

  Future<void> save(VisualProgress progress) async {
    await _prefs.setVisualCurriculumDay(progress.curriculumDay);
    await _prefs.setVisualRoundsCompletedToday(progress.roundsCompletedToday);
    if (progress.lastSessionDateIso != null) {
      await _prefs.setVisualLastSessionDate(progress.lastSessionDateIso!);
    }
    if (progress.programStartDateIso != null) {
      await _prefs.setVisualProgramStartDate(progress.programStartDateIso!);
    }
  }

  Future<VisualProgress> ensureProgramStart() async {
    final current = load();
    if (current.programStartDateIso != null) return current;
    final today = DateTime.now().toIso8601String().split('T').first;
    final updated = current.copyWith(programStartDateIso: today);
    await save(updated);
    return updated;
  }

  int curriculumDayFromStart(VisualProgress progress) {
    final startIso = progress.programStartDateIso;
    if (startIso == null) return progress.curriculumDay.clamp(1, 9999);
    final start = DateTime.parse(startIso);
    final now = DateTime.now();
    final days = now.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
    return days.clamp(1, 9999);
  }

  bool canStartAnotherRoundToday(VisualProgress progress, int dailyRepetitions) {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (progress.lastSessionDateIso != today) return true;
    return progress.roundsCompletedToday < dailyRepetitions;
  }

  Future<VisualProgress> completeRound(VisualProgress current) async {
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
