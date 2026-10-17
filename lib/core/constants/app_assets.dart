class AppAssets {
  AppAssets._();

  static const String logoBaby = 'assets/images/byanour-baby.png';

  /// BeBo-style 3D mascot illustrations. Replace PNG files in `assets/images/`
  /// with your exports (same filenames) without changing code.
  static const String mascotCupLying = 'assets/images/bebo_mascot_cup_lying.png';
  static const String mascotSpoonSitting = 'assets/images/bebo_mascot_spoon_sitting.png';
  static const String mascotCapLying = 'assets/images/bebo_mascot_cap_lying.png';
  static const String mascotGirlStanding = 'assets/images/bebo_mascot_girl_standing.png';
  static const String mascotEmpty = 'assets/images/bebo_empty.png';
  static const String mascotOffline = 'assets/images/bebo_offline.png';

  static const List<String> arenaMascots = [
    mascotCapLying,
    mascotSpoonSitting,
    mascotGirlStanding,
    mascotCupLying,
  ];

  static String mascotAt(int index) => arenaMascots[index % arenaMascots.length];

  static String mascotForTrack(String id) => switch (id) {
        'quran' => mascotCapLying,
        'visual' => mascotSpoonSitting,
        'math' => mascotGirlStanding,
        'emotional' => mascotCupLying,
        'live' => mascotGirlStanding,
        'courses' => mascotSpoonSitting,
        _ => mascotCapLying,
      };
  static const String heroQuran = 'assets/images/hero_quran.png';
  static const String heroMath = 'assets/images/hero_math.png';
  static const String heroVisual = 'assets/images/hero_visual.png';
  static const String heroEmotional = 'assets/images/hero_emotional.png';

  /// Pulled from Arena marketing site (community faces + club).
  static const String arenaAvatar1 = 'assets/images/arena/avatar_1.jpg';
  static const String arenaAvatar2 = 'assets/images/arena/avatar_2.jpg';
  static const String arenaAvatar3 = 'assets/images/arena/avatar_3.jpg';
  static const String arenaMothersClub = 'assets/images/arena/mothers_club.jpg';
}
