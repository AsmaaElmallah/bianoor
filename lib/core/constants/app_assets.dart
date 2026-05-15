class AppAssets {
  AppAssets._();

  static const String logoBaby = 'assets/images/byanour-baby.png';

  /// BeBo-style 3D mascot illustrations. Replace PNG files in `assets/images/`
  /// with your exports (same filenames) without changing code.
  static const String mascotCupLying = 'assets/images/bebo_mascot_cup_lying.png';
  static const String mascotSpoonSitting = 'assets/images/bebo_mascot_spoon_sitting.png';
  static const String mascotCapLying = 'assets/images/bebo_mascot_cap_lying.png';
  static const String mascotGirlStanding = 'assets/images/bebo_mascot_girl_standing.png';

  // Accept both naming conventions so the app keeps working
  // if files are renamed later (onboarding_1.mp4 or video_1.mp4).
  static List<String> get onboardingVideoCandidates {
    const max = 8;
    return List.generate(max, (i) {
      final n = i + 1;
      return 'assets/videos/onboarding_$n.mp4';
    });
  }

  static List<String> get legacyVideoCandidates {
    const max = 8;
    return List.generate(max, (i) {
      final n = i + 1;
      return 'assets/videos/video_$n.mp4';
    });
  }
}
