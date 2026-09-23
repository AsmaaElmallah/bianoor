import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../curriculum/data/progress_sync_service.dart';
import '../data/quran_progress_storage.dart';
import '../data/quran_reciters_data.dart';
import '../data/quran_repository.dart';
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
    this.cloudReady = false,
  });

  final QuranProgress progress;
  final int babyAgeMonths;
  final int dailyRepetitions;
  final int daysPerKhatmah;
  final QuranKhatmah currentKhatmah;
  final QuranSession currentSession;
  final bool cloudReady;

  bool get canListenMoreToday {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (progress.lastListenDateIso != today) return true;
    return progress.sessionsCompletedToday < dailyRepetitions;
  }

  bool get hasPublishedAudio =>
      currentSession.audioUrl != null && currentSession.audioUrl!.isNotEmpty;
}

class QuranCurriculumController extends StateNotifier<QuranCurriculumState> {
  QuranCurriculumController(this._ref)
      : super(_skeletonState(_ref)) {
    _storage = QuranProgressStorage(_ref.read(prefsServiceProvider));
    _hydrateFromCloud();
  }

  final Ref _ref;
  late final QuranProgressStorage _storage;

  static QuranCurriculumState _skeletonState(Ref ref) {
    final prefs = ref.read(prefsServiceProvider);
    final storage = QuranProgressStorage(prefs);
    final progress = storage.load();
    final ageRange = babyAgeRangeFromIndex(prefs.getBabyAgeRangeIndex());
    final months = approximateMonthsFromAgeRange(ageRange);
    final khatmahIndex = progress.currentKhatmahIndex;
    final repetitions = dailySessionsForKhatmah(khatmahIndex);
    final khatmah = khatmahByIndex(khatmahIndex);
    return QuranCurriculumState(
      progress: progress,
      babyAgeMonths: months,
      dailyRepetitions: repetitions,
      daysPerKhatmah: daysPerKhatmahForIndex(khatmahIndex),
      currentKhatmah: khatmah,
      currentSession: QuranSession(
        khatmahIndex: khatmahIndex,
        sessionIndex: progress.currentSessionIndex,
      ),
      cloudReady: false,
    );
  }

  Future<void> _hydrateFromCloud() async {
    final progress = _storage.load();
    final khatmahIndex = progress.currentKhatmahIndex;
    final session = await _ref.read(quranRepositoryProvider).resolveSession(
          khatmahIndex: khatmahIndex,
          sessionIndex: progress.currentSessionIndex,
        );
    if (!mounted) return;
    final ageRange =
        babyAgeRangeFromIndex(_ref.read(prefsServiceProvider).getBabyAgeRangeIndex());
    state = QuranCurriculumState(
      progress: progress,
      babyAgeMonths: approximateMonthsFromAgeRange(ageRange),
      dailyRepetitions: dailySessionsForKhatmah(khatmahIndex),
      daysPerKhatmah: daysPerKhatmahForIndex(khatmahIndex),
      currentKhatmah: khatmahByIndex(khatmahIndex),
      currentSession: session,
      cloudReady: true,
    );
  }

  Future<void> refresh() async {
    state = _skeletonState(_ref);
    await _hydrateFromCloud();
  }

  Future<void> jumpToKhatmah(int khatmahIndex) async {
    final progress = state.progress.copyWith(
      currentKhatmahIndex: khatmahIndex.clamp(1, quranTargetKhatmahCount),
      currentSessionIndex: 1,
    );
    await _storage.save(progress);
    await refresh();
  }

  Future<void> completeCurrentSession() async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final updated = await _storage.completeSession(
      current: state.progress,
      dailyRepetitions: state.dailyRepetitions,
      todayIso: today,
    );
    final khatmahIndex = updated.currentKhatmahIndex;
    final session = await _ref.read(quranRepositoryProvider).resolveSession(
          khatmahIndex: khatmahIndex,
          sessionIndex: updated.currentSessionIndex,
        );
    if (!mounted) return;
    state = QuranCurriculumState(
      progress: updated,
      babyAgeMonths: state.babyAgeMonths,
      dailyRepetitions: dailySessionsForKhatmah(khatmahIndex),
      daysPerKhatmah: daysPerKhatmahForIndex(khatmahIndex),
      currentKhatmah: khatmahByIndex(khatmahIndex),
      currentSession: session,
      cloudReady: true,
    );

    await _ref.read(progressSyncServiceProvider).pushTrack(
          trackId: 'quran',
          metadata: {
            'khatmah_index': updated.currentKhatmahIndex,
            'session_index': updated.currentSessionIndex,
            'sessions_completed_today': updated.sessionsCompletedToday,
            'completed_khatmahs': updated.completedKhatmahsCount,
          },
        );
  }

  bool canStartAnotherSessionToday() => state.canListenMoreToday;
}

final quranCurriculumProvider =
    StateNotifierProvider<QuranCurriculumController, QuranCurriculumState>(
  (ref) => QuranCurriculumController(ref),
);
