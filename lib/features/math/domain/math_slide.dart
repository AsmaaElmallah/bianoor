class MathSlide {
  const MathSlide({
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

class MathRoundStep {
  const MathRoundStep({
    required this.trackLabel,
    required this.slide,
    required this.slideIndexInTrack,
    required this.totalSlidesInTrack,
  });

  final String trackLabel;
  final MathSlide slide;
  final int slideIndexInTrack;
  final int totalSlidesInTrack;
}
