class MathSlide {
  const MathSlide({
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
