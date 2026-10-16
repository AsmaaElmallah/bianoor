import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/prefs_service.dart';
import '../../content/data/content_remote_data_source.dart';
import '../../library/data/library_content_repository.dart';
import '../domain/onboarding_video_ref.dart';

/// Picks the next onboarding video each time the screen is opened.
/// Source: published rows in Supabase `onboarding_videos` only (dashboard).
class VideoRotationService {
  VideoRotationService(this._prefs, this._remote);

  final PrefsService _prefs;
  final ContentRemoteDataSource _remote;

  Future<List<OnboardingVideoRef>> _fetchCloud() async {
    final rows = await _remote.fetchPublishedOnboardingVideos();
    final videos = <OnboardingVideoRef>[];
    for (final row in rows) {
      final youtubeId = (row['youtube_video_id'] as String?)?.trim();
      if (youtubeId != null && youtubeId.isNotEmpty) {
        videos.add(OnboardingVideoRef(youtubeId: youtubeId));
        continue;
      }
      final url = (row['video_url'] as String?)?.trim();
      if (url == null || url.isEmpty) continue;
      videos.add(OnboardingVideoRef(networkUrl: url));
    }
    if (kDebugMode) {
      debugPrint('[Onboarding] cloud videos: ${videos.length}');
    }
    return videos;
  }

  Future<List<OnboardingVideoRef>> getAvailableVideos() => _fetchCloud();

  Future<void> saveNextStartIndex(int index) async {
    final videos = await _fetchCloud();
    if (videos.isEmpty) {
      await _prefs.setVideoIndex(0);
      return;
    }
    await _prefs.setVideoIndex(index % videos.length);
  }

  Future<int> peekCurrentIndex() async {
    final videos = await _fetchCloud();
    if (videos.isEmpty) return 0;
    return _prefs.getVideoIndex() % videos.length;
  }
}

final videoRotationServiceProvider = Provider<VideoRotationService>((ref) {
  return VideoRotationService(
    ref.read(prefsServiceProvider),
    ref.watch(contentRemoteDataSourceProvider),
  );
});
