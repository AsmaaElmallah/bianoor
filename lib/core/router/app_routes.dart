class AppRoutes {

  AppRoutes._();



  static const splash = '/splash';

  static const videoIntro = '/video-intro';

  static const login = '/login';

  static const signup = '/signup';

  static const language = '/language';

  static const rules = '/rules';

  static const subscription = '/subscription';

  static const onboardingQuestions = '/onboarding-questions';

  static const onboardingSurvey = '/onboarding-survey';

  static const nutrition = '/nutrition';

  static const sleep = '/sleep';

  static const skills = '/skills';

  static const home = '/home';

  static const homeFeature = '/home/feature/:id';
  static const libraryMedia = '/home/library/:categoryId';
  static const libraryMediaWatch = '/home/library/:categoryId/watch';

  static const exercises = '/home/exercises';
  static const exercisesHub = '/home/exercises/:ageGroupId';

  static const activities = '/home/activities';
  static const activitiesHub = '/home/activities/:ageGroupId';



  /// مسار الدروس / الختمات (الصفحة الشاملة — نقطة الدخول من الرئيسية).

  static const mathJourney = '/home/math';

  static const mathPlayer = '/home/math/player';

  static const mathLessonDays = '/home/math/:lessonIndex';

  static const mathRoadmap = '/home/math/roadmap';



  static const visualJourney = '/home/visual';

  static const visualPlayer = '/home/visual/player';

  static const visualLessonDays = '/home/visual/:lessonIndex';

  static const visualRoadmap = '/home/visual/roadmap';



  static const emotionalJourney = '/home/emotional';

  static const emotionalPlayer = '/home/emotional/player';

  static const emotionalLessonDays = '/home/emotional/:lessonIndex';

  static const emotionalRoadmap = '/home/emotional/roadmap';



  static const quranJourney = '/home/quran';

  static const quranPlayer = '/home/quran/player';

  static const quranKhatmahDays = '/home/quran/:khatmahIndex';

  static const quranCelebration = '/home/quran/celebration/:khatmahIndex';



  static String homeFeaturePath(String id) => '/home/feature/$id';

  static String libraryMediaPath(String categoryId) => '/home/library/$categoryId';

  static const exercisesPath = '/home/exercises';

  static String exercisesHubPath(String ageGroupId) => '/home/exercises/$ageGroupId';

  static const activitiesPath = '/home/activities';

  static String activitiesHubPath(String ageGroupId) => '/home/activities/$ageGroupId';

  static String libraryMediaWatchPath(
    String categoryId, {
    String? videoId,
    String? playlistId,
    required String title,
  }) {
    final query = <String>[
      if (title.isNotEmpty) 'title=${Uri.encodeComponent(title)}',
      if (videoId != null && videoId.isNotEmpty) 'v=$videoId',
      if (playlistId != null && playlistId.isNotEmpty) 'list=$playlistId',
    ];
    return '/home/library/$categoryId/watch?${query.join('&')}';
  }



  static String quranKhatmahDaysPath(int khatmahIndex) =>

      '/home/quran/$khatmahIndex';



  static String quranCelebrationPath(int khatmahIndex) =>

      '/home/quran/celebration/$khatmahIndex';



  static String mathLessonDaysPath(int lessonIndex) =>

      '/home/math/$lessonIndex';



  static String visualLessonDaysPath(int lessonIndex) =>

      '/home/visual/$lessonIndex';



  static String emotionalLessonDaysPath(int lessonIndex) =>

      '/home/emotional/$lessonIndex';

}

