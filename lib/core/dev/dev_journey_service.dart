import '../storage/prefs_service.dart';
import '../../features/curriculum/domain/curriculum_shared_schedule.dart';
import '../../features/quran/domain/quran_age_schedule.dart';

/// أدوات تجربة: فتح الرحلة الكاملة (٧٣٠ يوم) محلياً على الجهاز.
class DevJourneyService {
  const DevJourneyService(this._prefs);

  final PrefsService _prefs;

  static const int fullProgramDay = curriculumProgramTotalDays;

  Future<void> unlockFullTwoYearJourney() async {
    final startIso = DateTime.now()
        .subtract(const Duration(days: fullProgramDay - 1))
        .toIso8601String()
        .split('T')
        .first;
    final today = DateTime.now().toIso8601String().split('T').first;

    await _prefs.setDevBypassProgramCalendar(true);
    await _prefs.setDevUnlockAllLessons(true);

    await _prefs.setMathCurriculumDay(fullProgramDay);
    await _prefs.setMathProgramStartDate(startIso);
    await _prefs.setMathRoundsCompletedToday(0);
    await _prefs.setMathLastSessionDate(today);

    await _prefs.setVisualCurriculumDay(fullProgramDay);
    await _prefs.setVisualProgramStartDate(startIso);
    await _prefs.setVisualRoundsCompletedToday(0);
    await _prefs.setVisualLastSessionDate(today);

    await _prefs.setEmotionalCurriculumDay(fullProgramDay);
    await _prefs.setEmotionalProgramStartDate(startIso);
    await _prefs.setEmotionalRoundsCompletedToday(0);
    await _prefs.setEmotionalLastSessionDate(today);

    await _prefs.setQuranKhatmahIndex(quranTargetKhatmahCount);
    await _prefs.setQuranSessionIndex(quranSessionsPerKhatmah);
    await _prefs.setQuranCompletedKhatmahs(quranTargetKhatmahCount);
    await _prefs.setQuranSessionsCompletedToday(0);
    await _prefs.setQuranLastListenDate(today);

    // المناهج: اليوم ٧٣٠ = كل الدروس مكتملة حسب منطق curriculumIsLessonFullyComplete
  }

  Future<void> resetJourneyToDayOne() async {
    await _prefs.setDevBypassProgramCalendar(false);
    await _prefs.setDevUnlockAllLessons(false);

    const day = 1;
    final today = DateTime.now().toIso8601String().split('T').first;
    final startIso = today;

    await _prefs.setMathCurriculumDay(day);
    await _prefs.setMathProgramStartDate(startIso);
    await _prefs.setMathRoundsCompletedToday(0);

    await _prefs.setVisualCurriculumDay(day);
    await _prefs.setVisualProgramStartDate(startIso);
    await _prefs.setVisualRoundsCompletedToday(0);

    await _prefs.setEmotionalCurriculumDay(day);
    await _prefs.setEmotionalProgramStartDate(startIso);
    await _prefs.setEmotionalRoundsCompletedToday(0);

    await _prefs.setQuranKhatmahIndex(1);
    await _prefs.setQuranSessionIndex(1);
    await _prefs.setQuranCompletedKhatmahs(0);
    await _prefs.setQuranSessionsCompletedToday(0);
  }
}
