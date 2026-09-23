import '../../../core/storage/prefs_service.dart';
import '../domain/math_progress.dart';

class MathProgressStorage {
  MathProgressStorage(this._prefs);

  final PrefsService _prefs;

  MathProgress load() {
    return MathProgress(
      curriculumDay: _prefs.getMathCurriculumDay(),
      roundsCompletedToday: _prefs.getMathRoundsCompletedToday(),
      lastSessionDateIso: _prefs.getMathLastSessionDate(),
      programStartDateIso: _prefs.getMathProgramStartDate(),
    );
  }

  Future<void> save(MathProgress progress) async {
    await _prefs.setMathCurriculumDay(progress.curriculumDay);
    await _prefs.setMathRoundsCompletedToday(progress.roundsCompletedToday);
    if (progress.lastSessionDateIso != null) {
      await _prefs.setMathLastSessionDate(progress.lastSessionDateIso!);
    }
    if (progress.programStartDateIso != null) {
      await _prefs.setMathProgramStartDate(progress.programStartDateIso!);
    }
  }

  Future<MathProgress> ensureProgramStart() async {
    final current = load();
    if (current.programStartDateIso != null) return current;
    final today = DateTime.now().toIso8601String().split('T').first;
    final updated = current.copyWith(programStartDateIso: today);
    await save(updated);
    return updated;
  }

  int curriculumDayFromStart(MathProgress progress) {
    final startIso = progress.programStartDateIso;
    if (startIso == null) return progress.curriculumDay.clamp(1, 9999);
    final start = DateTime.parse(startIso);
    final now = DateTime.now();
    final days = now.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
    return days.clamp(1, 9999);
  }

  bool canStartAnotherRoundToday(MathProgress progress, int dailyRepetitions) {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (progress.lastSessionDateIso != today) return true;
    return progress.roundsCompletedToday < dailyRepetitions;
  }

  Future<MathProgress> completeRound(MathProgress current) async {
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

  Future<MathProgress> advanceDay(MathProgress current) async {
    final updated = current.copyWith(curriculumDay: current.curriculumDay + 1);
    await save(updated);
    return updated;
  }
}
