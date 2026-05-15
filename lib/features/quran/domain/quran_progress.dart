import 'package:flutter/foundation.dart';

import 'quran_age_schedule.dart';

@immutable
class QuranProgress {
  const QuranProgress({
    this.currentKhatmahIndex = 1,
    this.currentSessionIndex = 1,
    this.completedKhatmahsCount = 0,
    this.sessionsCompletedToday = 0,
    this.lastListenDateIso,
  });

  final int currentKhatmahIndex;
  final int currentSessionIndex;
  final int completedKhatmahsCount;
  final int sessionsCompletedToday;
  final String? lastListenDateIso;

  double sessionFractionForKhatmah(int khatmahIndex) =>
      (currentSessionIndex - 1) / quranSessionsPerKhatmah;

  QuranProgress copyWith({
    int? currentKhatmahIndex,
    int? currentSessionIndex,
    int? completedKhatmahsCount,
    int? sessionsCompletedToday,
    String? lastListenDateIso,
  }) {
    return QuranProgress(
      currentKhatmahIndex: currentKhatmahIndex ?? this.currentKhatmahIndex,
      currentSessionIndex: currentSessionIndex ?? this.currentSessionIndex,
      completedKhatmahsCount:
          completedKhatmahsCount ?? this.completedKhatmahsCount,
      sessionsCompletedToday:
          sessionsCompletedToday ?? this.sessionsCompletedToday,
      lastListenDateIso: lastListenDateIso ?? this.lastListenDateIso,
    );
  }
}
