import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/data/content_remote_data_source.dart';
import '../../library/data/library_content_repository.dart';
import '../domain/quran_session.dart';

class QuranRepository {
  QuranRepository(this._remote);

  final ContentRemoteDataSource _remote;

  /// Cloud-only: published session with signed audio URL, or empty (no local fallback).
  Future<QuranSession> resolveSession({
    required int khatmahIndex,
    required int sessionIndex,
  }) async {
    final row = await _remote.fetchPublishedQuranSession(
      khatmah: khatmahIndex,
      sessionNumber: sessionIndex,
    );
    if (row == null) {
      return QuranSession(
        khatmahIndex: khatmahIndex,
        sessionIndex: sessionIndex,
      );
    }

    final storagePath = row['storage_path'] as String?;
    String? audioUrl;
    if (storagePath != null && storagePath.isNotEmpty) {
      audioUrl = await _remote.signedQuranAudioUrl(storagePath);
    }

    final duration = row['duration_minutes'] as int?;

    return QuranSession(
      khatmahIndex: khatmahIndex,
      sessionIndex: sessionIndex,
      durationMinutes: duration ?? 15,
      audioUrl: audioUrl,
    );
  }

  /// Cloud-only list of published sessions for a khatmah (empty if none published).
  Future<List<QuranSession>> fetchKhatmahSessions(int khatmahIndex) async {
    final rows =
        await _remote.fetchPublishedQuranSessionsForKhatmah(khatmahIndex);
    if (rows.isEmpty) return [];

    final sessions = <QuranSession>[];
    for (final row in rows) {
      final sessionNumber = row['session_number'] as int;
      final storagePath = row['storage_path'] as String?;
      String? audioUrl;
      if (storagePath != null && storagePath.isNotEmpty) {
        audioUrl = await _remote.signedQuranAudioUrl(storagePath);
      }
      sessions.add(
        QuranSession(
          khatmahIndex: khatmahIndex,
          sessionIndex: sessionNumber,
          durationMinutes: (row['duration_minutes'] as int?) ?? 15,
          audioUrl: audioUrl,
        ),
      );
    }
    return sessions;
  }
}

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository(ref.watch(contentRemoteDataSourceProvider));
});
