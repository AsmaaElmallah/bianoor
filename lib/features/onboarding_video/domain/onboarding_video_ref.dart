class OnboardingVideoRef {
  const OnboardingVideoRef({this.networkUrl, this.assetPath, this.youtubeId});

  final String? networkUrl;
  final String? assetPath;
  final String? youtubeId;

  bool get isYoutube {
    final id = youtubeId?.trim();
    return id != null && id.isNotEmpty;
  }

  bool get isNetwork {
    final url = networkUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  String get source => isYoutube
      ? youtubeId!.trim()
      : isNetwork
          ? networkUrl!.trim()
          : (assetPath ?? '');
}
