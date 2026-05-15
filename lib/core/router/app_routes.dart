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
  static const quranLesson = '/home/quran';
  static const quranPlayer = '/home/quran/player';
  static const quranJourney = '/home/quran/journey';
  static const quranKhatmahDays = '/home/quran/journey/:khatmahIndex';
  static const quranCelebration = '/home/quran/celebration/:khatmahIndex';

  static String homeFeaturePath(String id) => '/home/feature/$id';

  static String quranKhatmahDaysPath(int khatmahIndex) =>
      '/home/quran/journey/$khatmahIndex';

  static String quranCelebrationPath(int khatmahIndex) =>
      '/home/quran/celebration/$khatmahIndex';
}
