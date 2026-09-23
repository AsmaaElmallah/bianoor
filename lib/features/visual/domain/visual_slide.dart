class VisualSlide {
  const VisualSlide({
    required this.packageId,
    required this.slideIndex,
    required this.assetFolder,
    required this.durationSec,
    required this.imageAssets,
    this.audioAsset,
    this.imageUrls = const [],
    this.audioUrl,
  });

  final String packageId;
  final int slideIndex;
  final String assetFolder;
  final double durationSec;
  final List<String> imageAssets;
  final String? audioAsset;
  final List<String> imageUrls;
  final String? audioUrl;

  bool get hasNetworkImage => imageUrls.isNotEmpty;
  bool get hasNetworkAudio => audioUrl != null && audioUrl!.isNotEmpty;
}

class VisualRoundStep {
  const VisualRoundStep({
    required this.slide,
    required this.slideIndexInLesson,
    required this.totalSlidesInLesson,
  });

  final VisualSlide slide;
  final int slideIndexInLesson;
  final int totalSlidesInLesson;
}
