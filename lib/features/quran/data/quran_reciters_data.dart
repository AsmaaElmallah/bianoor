import '../domain/quran_age_schedule.dart';
import '../domain/quran_khatmah.dart';
import '../domain/quran_reciter.dart';
import '../domain/quran_session.dart';

/// Active reciter for all khatmahs until more voices are bundled.
const QuranReciter quranDefaultReciter = QuranReciter(
  id: 'ahmed_khader',
  name: 'أحمد خضر',
);

/// Reciters that have bundled session audio under assets/audio/quran/{id}/.
const recitersWithBundledAudio = <String>{
  'ahmed_khader',
};

bool reciterHasBundledAudio(String reciterId) =>
    recitersWithBundledAudio.contains(reciterId);

QuranReciter reciterForKhatmahIndex(int _) => quranDefaultReciter;

List<QuranKhatmah> buildAllKhatmahs() {
  return List.generate(quranTargetKhatmahCount, (i) {
    final index = i + 1;
    return QuranKhatmah(
      index: index,
      reciter: reciterForKhatmahIndex(index),
      qiraat: index > 40 ? 'قراءة متنوعة' : null,
    );
  });
}

QuranKhatmah khatmahByIndex(int index) {
  final all = buildAllKhatmahs();
  if (index < 1 || index > all.length) {
    return QuranKhatmah(index: 1, reciter: quranDefaultReciter);
  }
  return all[index - 1];
}

String? localAssetForSession({
  required String reciterId,
  required int sessionIndex,
}) {
  if (!reciterHasBundledAudio(reciterId)) return null;
  if (reciterId == 'ahmed_khader') {
    final padded = sessionIndex.toString().padLeft(3, '0');
    return 'assets/audio/quran/ahmed_khader/half_hizb/session_$padded.mp3';
  }
  final padded = sessionIndex.toString().padLeft(3, '0');
  return 'assets/audio/quran/$reciterId/half_hizb/session_$padded.mp3';
}

QuranSession sessionFor({
  required int khatmahIndex,
  required int sessionIndex,
}) {
  final reciter = reciterForKhatmahIndex(khatmahIndex);
  return QuranSession(
    khatmahIndex: khatmahIndex,
    sessionIndex: sessionIndex,
    localAsset: localAssetForSession(
      reciterId: reciter.id,
      sessionIndex: sessionIndex,
    ),
  );
}

List<QuranSession> sessionsForKhatmah(int khatmahIndex) {
  return List.generate(
    quranSessionsPerKhatmah,
    (i) => sessionFor(khatmahIndex: khatmahIndex, sessionIndex: i + 1),
  );
}
