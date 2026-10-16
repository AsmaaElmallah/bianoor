import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../emotional/application/emotional_curriculum_provider.dart';
import '../../live/data/live_repository.dart';
import '../../live/domain/live_session.dart';
import '../../math/application/math_curriculum_provider.dart';
import '../../quran/application/quran_curriculum_provider.dart';
import '../../visual/application/visual_curriculum_provider.dart';

enum HomeTrackId { quran, visual, math, emotional }

class HomeTrackStep {
  const HomeTrackStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.playRoute,
    required this.done,
  });

  final HomeTrackId id;
  final String title;
  final String subtitle;

  /// Journey / map screen for the track.
  final String route;

  /// Direct lesson player for «خطة اليوم» / يلا نبدأ.
  final String playRoute;
  final bool done;
}

class HomeTodayJourney {
  const HomeTodayJourney({
    required this.babyName,
    required this.steps,
    this.upcomingLive,
  });

  final String babyName;
  final List<HomeTrackStep> steps;
  final LiveSession? upcomingLive;

  int get doneCount => steps.where((s) => s.done).length;
  int get totalCount => steps.length;
  bool get allDone => totalCount > 0 && doneCount >= totalCount;

  HomeTrackStep? get nextStep {
    for (final s in steps) {
      if (!s.done) return s;
    }
    return null;
  }

  /// Rough minutes left (~2.5 min per open track).
  int get minutesLeft {
    final left = totalCount - doneCount;
    if (left <= 0) return 0;
    return (left * 2.5).round().clamp(1, 30);
  }
}

String _todayIso() => DateTime.now().toIso8601String().split('T').first;

bool _trackDoneToday({
  required String? lastDateIso,
  required int completedToday,
  required int needed,
}) {
  if (needed <= 0) return true;
  return lastDateIso == _todayIso() && completedToday >= needed;
}

final homeTodayJourneyProvider = Provider<HomeTodayJourney>((ref) {
  final prefs = ref.watch(prefsServiceProvider);
  final babyName = prefs.getBabyName() ?? 'طفلك';

  final quran = ref.watch(quranCurriculumProvider);
  final math = ref.watch(mathCurriculumProvider).valueOrNull;
  final visual = ref.watch(visualCurriculumProvider).valueOrNull;
  final emotional = ref.watch(emotionalCurriculumProvider).valueOrNull;

  final quranDone = _trackDoneToday(
    lastDateIso: quran.progress.lastListenDateIso,
    completedToday: quran.progress.sessionsCompletedToday,
    needed: quran.dailyRepetitions,
  );
  final mathDone = math == null
      ? false
      : !math.rules.isTrainingDay ||
          _trackDoneToday(
            lastDateIso: math.progress.lastSessionDateIso,
            completedToday: math.progress.roundsCompletedToday,
            needed: math.rules.repetitionsPerDay,
          );
  final visualDone = visual == null
      ? false
      : !visual.rules.isTrainingDay ||
          _trackDoneToday(
            lastDateIso: visual.progress.lastSessionDateIso,
            completedToday: visual.progress.roundsCompletedToday,
            needed: visual.rules.repetitionsPerDay,
          );
  final emotionalDone = emotional == null
      ? false
      : !emotional.rules.isTrainingDay ||
          _trackDoneToday(
            lastDateIso: emotional.progress.lastSessionDateIso,
            completedToday: emotional.progress.roundsCompletedToday,
            needed: emotional.rules.repetitionsPerDay,
          );

  final steps = <HomeTrackStep>[
    HomeTrackStep(
      id: HomeTrackId.quran,
      title: 'القرآن الكريم',
      subtitle: quranDone
          ? 'خلصتِ جلسة النهارده'
          : 'كمّلي: ${quran.currentSession.title}',
      route: AppRoutes.quranJourney,
      playRoute: AppRoutes.quranPlayer,
      done: quranDone,
    ),
    HomeTrackStep(
      id: HomeTrackId.visual,
      title: 'التحفيز البصري',
      subtitle: visualDone ? 'خلص درس النهارده' : 'درس اليوم جاهز',
      route: AppRoutes.visualJourney,
      playRoute: AppRoutes.visualPlayer,
      done: visualDone,
    ),
    HomeTrackStep(
      id: HomeTrackId.math,
      title: 'الحساب النقطي',
      subtitle: mathDone
          ? 'خلص درس النهارده'
          : 'اليوم ${math?.curriculumDay ?? '—'}',
      route: AppRoutes.mathJourney,
      playRoute: AppRoutes.mathPlayer,
      done: mathDone,
    ),
    HomeTrackStep(
      id: HomeTrackId.emotional,
      title: 'الذكاء العاطفي',
      subtitle: emotionalDone ? 'خلص درس النهارده' : 'درس اليوم جاهز',
      route: AppRoutes.emotionalJourney,
      playRoute: AppRoutes.emotionalPlayer,
      done: emotionalDone,
    ),
  ];

  LiveSession? upcoming;
  final lives = ref.watch(liveSessionsProvider).valueOrNull ?? const <LiveSession>[];
  final now = DateTime.now();
  final candidates = lives.where((s) {
    if (s.showAsEnded) return false;
    if (s.status == LiveStatus.live) return true;
    final at = s.scheduledAt;
    if (at == null) return false;
    final diff = at.difference(now);
    return !diff.isNegative && diff <= const Duration(hours: 48);
  }).toList()
    ..sort((a, b) {
      if (a.status == LiveStatus.live && b.status != LiveStatus.live) return -1;
      if (b.status == LiveStatus.live && a.status != LiveStatus.live) return 1;
      return (a.scheduledAt ?? now).compareTo(b.scheduledAt ?? now);
    });
  if (candidates.isNotEmpty) upcoming = candidates.first;

  return HomeTodayJourney(babyName: babyName, steps: steps, upcomingLive: upcoming);
});
