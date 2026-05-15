import 'package:flutter/foundation.dart';

import 'quran_age_schedule.dart';

/// One half-hizb listening session within a khatmah.
@immutable
class QuranSession {
  const QuranSession({
    required this.khatmahIndex,
    required this.sessionIndex,
    this.durationMinutes = quranHalfHizbDurationMinutes,
    this.localAsset,
    this.audioUrl,
  });

  final int khatmahIndex;
  final int sessionIndex;
  final int durationMinutes;
  final String? localAsset;
  final String? audioUrl;

  int get parentHizb => parentHizbForSession(sessionIndex);
  int get halfOfHizb => halfOfHizbForSession(sessionIndex);

  String get id =>
      'khatmah_${khatmahIndex.toString().padLeft(2, '0')}_session_${sessionIndex.toString().padLeft(3, '0')}';

  String get title => halfHizbSessionTitle(sessionIndex);
}
