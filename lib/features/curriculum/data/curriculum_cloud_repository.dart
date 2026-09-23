import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../../content/data/content_remote_data_source.dart';
import '../../library/data/library_content_repository.dart';

/// Cloud slide for math / visual / emotional players.
class CloudCurriculumSlide {
  const CloudCurriculumSlide({
    required this.id,
    required this.trackId,
    required this.lessonNumber,
    required this.globalIndex,
    required this.slideIndex,
    required this.dayIndexInLesson,
    required this.durationSec,
    this.packageId,
    this.title,
    this.imageUrl,
    this.audioUrl,
  });

  final String id;
  final String trackId;
  final int lessonNumber;
  final int globalIndex;
  final int slideIndex;
  final int dayIndexInLesson;
  final int durationSec;
  final String? packageId;
  final String? title;
  final String? imageUrl;
  final String? audioUrl;
}

final curriculumCloudRepositoryProvider = Provider<CurriculumCloudRepository>((ref) {
  return CurriculumCloudRepository(ref.watch(contentRemoteDataSourceProvider));
});

/// Published slides for a track — empty list means admin has not published yet
/// (no local asset fallback as source of truth).
final cloudSlidesProvider =
    FutureProvider.family<List<CloudCurriculumSlide>, String>((ref, trackId) {
  return ref.watch(curriculumCloudRepositoryProvider).fetchPublished(trackId);
});

class CurriculumCloudRepository {
  CurriculumCloudRepository(this._remote);

  final ContentRemoteDataSource _remote;

  Future<List<CloudCurriculumSlide>> fetchPublished(String trackId) async {
    if (!SupabaseBootstrap.isEnabled) return [];
    if (!SupabaseBootstrap.isReady) await SupabaseBootstrap.init();
    if (!SupabaseBootstrap.isReady) return [];

    try {
      final rows = await SupabaseBootstrap.client
          .from('curriculum_slides')
          .select()
          .eq('track_id', trackId)
          .eq('publish_status', 'published')
          .order('lesson_number')
          .order('global_index');

      final list = <CloudCurriculumSlide>[];
      for (final row in List<Map<String, dynamic>>.from(rows as List)) {
        final imagePath = row['image_storage_path'] as String?;
        final audioPath = row['audio_storage_path'] as String?;

        String? imageUrl;
        String? audioUrl;
        if (imagePath != null && imagePath.isNotEmpty) {
          imageUrl = await _signed(imagePath);
        }
        if (audioPath != null && audioPath.isNotEmpty) {
          audioUrl = await _signed(audioPath);
        }

        list.add(
          CloudCurriculumSlide(
            id: row['id'] as String,
            trackId: trackId,
            lessonNumber: row['lesson_number'] as int,
            globalIndex: row['global_index'] as int,
            slideIndex: row['slide_index'] as int,
            dayIndexInLesson: row['day_index_in_lesson'] as int,
            durationSec: (row['duration_sec'] as int?) ?? 45,
            packageId: row['package_id'] as String?,
            title: row['title'] as String?,
            imageUrl: imageUrl,
            audioUrl: audioUrl,
          ),
        );
      }
      return list;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[CurriculumCloud] $trackId failed: $e\n$st');
      return [];
    }
  }

  Future<String?> _signed(String path) async {
    try {
      return await SupabaseBootstrap.client.storage
          .from('slide-media')
          .createSignedUrl(path, 3600 * 6);
    } catch (_) {
      return null;
    }
  }
}
