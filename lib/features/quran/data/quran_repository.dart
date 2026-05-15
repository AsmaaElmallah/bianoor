import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quran_session.dart';
import 'quran_reciters_data.dart';

class QuranRepository {
  const QuranRepository();

  QuranSession getSession({
    required int khatmahIndex,
    required int sessionIndex,
  }) {
    return sessionFor(khatmahIndex: khatmahIndex, sessionIndex: sessionIndex);
  }

  List<QuranSession> getKhatmahSessions(int khatmahIndex) {
    return sessionsForKhatmah(khatmahIndex);
  }
}

final quranRepositoryProvider = Provider((ref) => const QuranRepository());
