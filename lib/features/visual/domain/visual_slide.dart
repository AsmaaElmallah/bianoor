class VisualSlide {
  const VisualSlide({
    required this.packageId,
    required this.slideIndex,
    required this.assetFolder,
    required this.durationSec,
    required this.imageAssets,
    this.audioAsset,
    this.imageNetworkUrls = const [],
    this.audioNetworkUrl,
  });

  final String packageId;
  final int slideIndex;
  final String assetFolder;
  final double durationSec;
  final List<String> imageAssets;
  final String? audioAsset;
  final List<String> imageNetworkUrls;
  final String? audioNetworkUrl;

  List<String> get displayImageSources =>
      imageNetworkUrls.isNotEmpty ? imageNetworkUrls : imageAssets;

  String? get playableAudio => audioNetworkUrl ?? audioAsset;

  bool get usesNetworkImage => imageNetworkUrls.isNotEmpty;
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
