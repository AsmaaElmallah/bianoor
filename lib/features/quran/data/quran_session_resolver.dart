import '../domain/quran_session.dart';
import 'quran_reciters_data.dart';
import 'quran_remote_data_source.dart';

/// يدمج جلسة محلية مع صوت السحابة إن وُجد.
class QuranSessionResolver {
  const QuranSessionResolver({QuranRemoteDataSource? remote})
      : _remote = remote ?? const QuranRemoteDataSource();

  final QuranRemoteDataSource _remote;

  Future<QuranSession> resolve({
    required int khatmahIndex,
    required int sessionIndex,
  }) async {
    final base = sessionFor(
      khatmahIndex: khatmahIndex,
      sessionIndex: sessionIndex,
    );

    final audioUrl = await _remote.signedUrlForSession(khatmahIndex, sessionIndex);
    if (audioUrl == null) return base;

    return QuranSession(
      khatmahIndex: khatmahIndex,
      sessionIndex: sessionIndex,
      durationMinutes: base.durationMinutes,
      localAsset: base.localAsset,
      audioUrl: audioUrl,
    );
  }
}
