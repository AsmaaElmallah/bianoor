import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/storage/prefs_service.dart';

/// Picks the next video asset path each time the screen is opened, then
/// advances the saved index modulo available files count.
class VideoRotationService {
  VideoRotationService(this._prefs);

  final PrefsService _prefs;

  Future<List<String>> _resolveAvailableAssets() async {
    final candidates = [
      ...AppAssets.onboardingVideoCandidates,
      ...AppAssets.legacyVideoCandidates,
    ];
    final existing = <String>[];
    for (final path in candidates) {
      try {
        await rootBundle.load(path);
        existing.add(path);
      } catch (_) {
        // Ignore missing assets.
      }
    }
    return existing.toSet().toList()..sort();
  }

  Future<List<String>> getAvailableVideos() => _resolveAvailableAssets();

  Future<void> saveNextStartIndex(int index) async {
    final assets = await _resolveAvailableAssets();
    if (assets.isEmpty) {
      await _prefs.setVideoIndex(0);
      return;
    }
    await _prefs.setVideoIndex(index % assets.length);
  }

  /// Returns the asset path for the current video and advances the rotation
  /// index for the next visit.
  Future<String> takeNextVideo() async {
    final assets = await _resolveAvailableAssets();
    if (assets.isEmpty) {
      throw StateError('No onboarding videos found in assets/videos.');
    }
    final index = _prefs.getVideoIndex() % assets.length;
    final asset = assets[index];
    await _prefs.setVideoIndex((index + 1) % assets.length);
    return asset;
  }

  Future<int> peekCurrentIndex() async {
    final assets = await _resolveAvailableAssets();
    if (assets.isEmpty) return 0;
    return _prefs.getVideoIndex() % assets.length;
  }

  Future<int> countAvailableVideos() async {
    final assets = await _resolveAvailableAssets();
    return assets.length;
  }
}

final videoRotationServiceProvider = Provider<VideoRotationService>((ref) {
  return VideoRotationService(ref.read(prefsServiceProvider));
});
