import 'package:flutter/foundation.dart';

import '../../features/emotional/domain/emotional_slide.dart';
import '../../features/math/domain/math_slide.dart';
import '../../features/visual/domain/visual_slide.dart';
import '../supabase/supabase_bootstrap.dart';

/// سجل شريحة من Supabase (بعد توقيع روابط Storage).
class CloudCurriculumSlide {
  const CloudCurriculumSlide({
    required this.id,
    required this.trackId,
    required this.lessonNumber,
    required this.globalIndex,
    required this.slideIndex,
    required this.packageId,
    required this.durationSec,
    this.imageUrl,
    this.audioUrl,
  });

  final String id;
  final String trackId;
  final int lessonNumber;
  final int globalIndex;
  final int slideIndex;
  final String packageId;
  final double durationSec;
  final String? imageUrl;
  final String? audioUrl;

  bool get isPlayable => imageUrl != null;

  MathSlide toMathSlide() {
    return MathSlide(
      packageId: packageId,
      slideIndex: slideIndex,
      assetFolder: 'cloud/$id',
      durationSec: durationSec,
      imageAssets: const [],
      imageNetworkUrls: imageUrl != null ? [imageUrl!] : const [],
      audioNetworkUrl: audioUrl,
    );
  }

  VisualSlide toVisualSlide() {
    return VisualSlide(
      packageId: packageId,
      slideIndex: slideIndex,
      assetFolder: 'cloud/$id',
      durationSec: durationSec,
      imageAssets: const [],
      imageNetworkUrls: imageUrl != null ? [imageUrl!] : const [],
      audioNetworkUrl: audioUrl,
    );
  }

  EmotionalSlide toEmotionalSlide() {
    return EmotionalSlide(
      packageId: packageId,
      slideIndex: slideIndex,
      assetFolder: 'cloud/$id',
      durationSec: durationSec,
      imageAssets: const [],
      imageNetworkUrls: imageUrl != null ? [imageUrl!] : const [],
      audioNetworkUrl: audioUrl,
    );
  }
}

class CurriculumSlidesRemoteDataSource {
  const CurriculumSlidesRemoteDataSource();

  Future<Map<int, CloudCurriculumSlide>> fetchPublishedByGlobalIndex(
    String trackId,
  ) async {
    if (!SupabaseBootstrap.isEnabled) {
      if (kDebugMode) debugPrint('[CurriculumSlides] Supabase disabled — skip fetch ($trackId)');
      return {};
    }

    if (!SupabaseBootstrap.isReady) {
      await SupabaseBootstrap.init();
    }
    final client = SupabaseBootstrap.client;

    final rows = await client
        .from('curriculum_slides')
        .select()
        .eq('track_id', trackId)
        .eq('publish_status', 'published')
        .order('global_index');

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (kDebugMode) {
      debugPrint('[CurriculumSlides] fetched ${list.length} published rows for $trackId');
    }
    final map = <int, CloudCurriculumSlide>{};

    for (final row in list) {
      final globalIndex = row['global_index'] as int?;
      if (globalIndex == null) continue;

      final imagePath = row['image_storage_path'] as String?;
      final audioPath = row['audio_storage_path'] as String?;

      String? imageUrl;
      String? audioUrl;

      if (imagePath != null && imagePath.isNotEmpty) {
        imageUrl = await client.storage.from('slide-media').createSignedUrl(imagePath, 3600);
      }
      if (audioPath != null && audioPath.isNotEmpty) {
        audioUrl = await client.storage.from('slide-media').createSignedUrl(audioPath, 3600);
      }

      if (imageUrl == null && audioUrl == null) continue;

      map[globalIndex] = CloudCurriculumSlide(
        id: row['id'] as String,
        trackId: trackId,
        lessonNumber: row['lesson_number'] as int? ?? 1,
        globalIndex: globalIndex,
        slideIndex: row['slide_index'] as int? ?? 1,
        packageId: row['package_id'] as String? ?? 'cloud',
        durationSec: (row['duration_sec'] as num?)?.toDouble() ?? 45,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );
    }

    return map;
  }
}
