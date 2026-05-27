import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../auth/application/auth_session_provider.dart';
import '../data/quran_progress_storage.dart';
import '../data/quran_reciters_data.dart';
import '../domain/quran_age_schedule.dart';
import '../domain/quran_khatmah.dart';
import '../domain/quran_progress.dart';
import '../domain/quran_session.dart';

class QuranCurriculumState {
  const QuranCurriculumState({
    required this.progress,
    required this.babyAgeMonths,
    required this.dailyRepetitions,
    required this.daysPerKhatmah,
    required this.currentKhatmah,
    required this.currentSession,
  });

  final QuranProgress progress;
  final int babyAgeMonths;
  final int dailyRepetitions;
  final int daysPerKhatmah;
  final QuranKhatmah currentKhatmah;
  final QuranSession currentSession;

  bool get canListenMoreToday {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (progress.lastListenDateIso != today) return true;
    return progress.sessionsCompletedToday < dailyRepetitions;
  }
}

final quranProgressStorageProvider = Provider<QuranProgressStorage>((ref) {
  return QuranProgressStorage(
    ref.watch(prefsServiceProvider),
    ref.watch(userProgressSyncProvider),
  );
});

class QuranCurriculumController extends StateNotifier<QuranCurriculumState> {
  QuranCurriculumController(this._ref)
      : super(_initialState(_ref)) {
    _storage = _ref.read(quranProgressStorageProvider);
  }

  final Ref _ref;
  late final QuranProgressStorage _storage;

  static QuranCurriculumState _initialState(Ref ref) {
    final prefs = ref.read(prefsServiceProvider);
    final storage = ref.read(quranProgressStorageProvider);
    final progress = storage.load();
    final ageRange = babyAgeRangeFromIndex(prefs.getBabyAgeRangeIndex());
    final months = approximateMonthsFromAgeRange(ageRange);
    final khatmahIndex = progress.currentKhatmahIndex;
    final repetitions = dailySessionsForKhatmah(khatmahIndex);
    final khatmah = khatmahByIndex(khatmahIndex);
    final session = sessionFor(
      khatmahIndex: khatmahIndex,
      sessionIndex: progress.currentSessionIndex,
    );
    return QuranCurriculumState(
      progress: progress,
      babyAgeMonths: months,
      dailyRepetitions: repetitions,
      daysPerKhatmah: daysPerKhatmahForIndex(khatmahIndex),
      currentKhatmah: khatmah,
      currentSession: session,
    );
  }

  Future<void> refresh() async {
    state = _initialState(_ref);
  }

  Future<void> jumpToKhatmah(int khatmahIndex) async {
    final progress = state.progress.copyWith(
      currentKhatmahIndex: khatmahIndex.clamp(1, quranTargetKhatmahCount),
      currentSessionIndex: 1,
    );
    await _storage.save(progress);
    state = _initialState(_ref);
  }

  Future<void> completeCurrentSession() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final updated = await _storage.completeSession(
      current: state.progress,
      dailyRepetitions: state.dailyRepetitions,
      todayIso: today,
    );
    final khatmahIndex = updated.currentKhatmahIndex;
    final repetitions = dailySessionsForKhatmah(khatmahIndex);
    final khatmah = khatmahByIndex(khatmahIndex);
    final session = sessionFor(
      khatmahIndex: khatmahIndex,
      sessionIndex: updated.currentSessionIndex,
    );
    state = QuranCurriculumState(
      progress: updated,
      babyAgeMonths: state.babyAgeMonths,
      dailyRepetitions: repetitions,
      daysPerKhatmah: daysPerKhatmahForIndex(khatmahIndex),
      currentKhatmah: khatmah,
      currentSession: session,
    );
  }

  bool canStartAnotherSessionToday() => state.canListenMoreToday;
}

final quranCurriculumProvider =
    StateNotifierProvider<QuranCurriculumController, QuranCurriculumState>(
  (ref) => QuranCurriculumController(ref),
);
