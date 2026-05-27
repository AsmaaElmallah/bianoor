import '../../../core/supabase/supabase_bootstrap.dart';

class QuranSessionRemoteRow {
  const QuranSessionRemoteRow({
    required this.id,
    required this.khatmah,
    required this.sessionNumber,
    this.storagePath,
    this.legacyAssetPath,
    this.durationMinutes,
    this.title,
    this.surahRange,
  });

  final String id;
  final int khatmah;
  final int sessionNumber;
  final String? storagePath;
  final String? legacyAssetPath;
  final int? durationMinutes;
  final String? title;
  final String? surahRange;
}

class QuranRemoteDataSource {
  const QuranRemoteDataSource();

  Future<List<QuranSessionRemoteRow>> fetchPublishedSessions() async {
    if (!SupabaseBootstrap.isEnabled) return [];

    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }

    final rows = await SupabaseBootstrap.client
        .from('quran_sessions')
        .select()
        .eq('publish_status', 'published')
        .order('khatmah')
        .order('session_number');

    return [
      for (final row in List<Map<String, dynamic>>.from(rows as List))
        QuranSessionRemoteRow(
          id: row['id'] as String,
          khatmah: row['khatmah'] as int,
          sessionNumber: row['session_number'] as int,
          storagePath: row['storage_path'] as String?,
          legacyAssetPath: row['legacy_asset_path'] as String?,
          durationMinutes: row['duration_minutes'] as int?,
          title: row['title'] as String?,
          surahRange: row['surah_range'] as String?,
        ),
    ];
  }

  Future<String?> signedAudioUrl(String storagePath) async {
    if (!SupabaseBootstrap.isReady) return null;
    try {
      return await SupabaseBootstrap.client.storage
          .from('quran-audio')
          .createSignedUrl(storagePath, 3600);
    } catch (_) {
      return null;
    }
  }

  Future<String?> signedUrlForSession(int khatmah, int sessionNumber) async {
    if (!SupabaseBootstrap.isEnabled) return null;

    final rows = await SupabaseBootstrap.client
        .from('quran_sessions')
        .select('storage_path')
        .eq('publish_status', 'published')
        .eq('khatmah', khatmah)
        .eq('session_number', sessionNumber)
        .maybeSingle();

    if (rows == null) return null;
    final path = rows['storage_path'] as String?;
    if (path == null || path.isEmpty) return null;
    return signedAudioUrl(path);
  }
}
