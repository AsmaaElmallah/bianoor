import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import 'home_menu_item.dart';

/// Track-themed lesson card colors — warmer & more vibrant.
class HomeLessonColors {
  HomeLessonColors._();

  static const quranBg   = AppColors.trackQuranLight;    // #FFF3CC gold tint
  static const quranIcon = AppColors.trackQuranGold;     // #FFAA00

  static const mathBg    = AppColors.trackMathLight;     // #FFE4DB orange tint
  static const mathIcon  = AppColors.trackMathOrange;    // #FF7043

  static const visualBg  = AppColors.trackVisualLight;  // #EFE3FF purple tint
  static const visualIcon= AppColors.trackVisualPurple; // #9C6FD6

  static const emotionalBg  = AppColors.trackEmotionalLight; // #FFE4EC coral tint
  static const emotionalIcon= AppColors.trackEmotionalRed;   // #F1758E
}

const homeMenuSections = <HomeMenuSection>[
  HomeMenuSection(
    id: 'start_learning',
    title: 'ابدأ التعلم',
    accentColor: AppColors.primary,
    layout: HomeSectionLayout.shortcutStrip,
    items: [
      HomeMenuItem(
        id: 'curriculum',
        title: 'المنهج',
        icon: Symbols.menu_book,
        children: [
          HomeMenuItem(
            id: 'curriculum_about',
            title: '🌸 ما هو المنهج ؟ ( اهدافه و اساليبه)',
            icon: Symbols.auto_stories,
          ),
          HomeMenuItem(
            id: 'parent_general_culture',
            title: 'ثقافة هامة للأمهات / ولي الأمر لطفلك',
            icon: Symbols.groups,
          ),
          HomeMenuItem(
            id: 'parent_health_culture',
            title: 'الثقافة الصحية',
            icon: Symbols.health_and_safety,
          ),
        ],
      ),
      HomeMenuItem(
        id: 'how_to_teach',
        title: '🌸 كيف ادررس طفلي ؟',
        icon: Symbols.location_on,
      ),
      HomeMenuItem(
        id: 'apply_activities',
        title: 'تطبيق الأنشطة',
        icon: Symbols.extension,
      ),
      HomeMenuItem(
        id: 'baby_exercises',
        title: 'الرياضة',
        icon: Symbols.fitness_center,
      ),
      HomeMenuItem(
        id: 'age_levels',
        title: 'المستويات العمرية',
        icon: Symbols.face,
        children: [
          HomeMenuItem(id: 'lesson_quran', title: 'دروس القرآن الكريم', icon: Symbols.menu_book),
          HomeMenuItem(id: 'lesson_math', title: 'دروس الحساب النقطي', icon: Symbols.grid_on),
          HomeMenuItem(id: 'lesson_visual', title: 'دروس التحفيز البصري', icon: Symbols.visibility),
          HomeMenuItem(id: 'lesson_emotional', title: 'دروس الذكاء العاطفي (المشاعر)', icon: Symbols.favorite),
        ],
      ),
    ],
  ),
  HomeMenuSection(
    id: 'lessons',
    title: 'الدروس',
    accentColor: AppColors.secondary,
    layout: HomeSectionLayout.pastelGrid,
    items: [
      HomeMenuItem(
        id: 'lesson_quran',
        title: 'القرآن الكريم',
        icon: Symbols.menu_book,
        cardColor: HomeLessonColors.quranBg,
        iconColor: HomeLessonColors.quranIcon,
      ),
      HomeMenuItem(
        id: 'lesson_math',
        title: 'الحساب النقطي',
        icon: Symbols.grid_on,
        cardColor: HomeLessonColors.mathBg,
        iconColor: HomeLessonColors.mathIcon,
      ),
      HomeMenuItem(
        id: 'lesson_visual',
        title: 'التحفيز البصري',
        icon: Symbols.visibility,
        cardColor: HomeLessonColors.visualBg,
        iconColor: HomeLessonColors.visualIcon,
      ),
      HomeMenuItem(
        id: 'lesson_emotional',
        title: 'الذكاء العاطفي',
        icon: Symbols.favorite,
        cardColor: HomeLessonColors.emotionalBg,
        iconColor: HomeLessonColors.emotionalIcon,
      ),
    ],
  ),
  HomeMenuSection(
    id: 'assessment',
    title: 'التقييم',
    accentColor: AppColors.tertiary,
    layout: HomeSectionLayout.listPanel,
    items: [
      HomeMenuItem(
        id: 'mother_assessment',
        title: 'تقييم الأم',
        icon: Symbols.family_restroom,
        children: [
          HomeMenuItem(id: 'aptitude_test', title: 'اختبار القدرات', icon: Symbols.psychology),
          HomeMenuItem(id: 'skills_test', title: 'اختبار المهارات', icon: Symbols.fact_check),
          HomeMenuItem(id: 'interests_test', title: 'فحص ميول الطفل وشغفه', icon: Symbols.interests),
        ],
      ),
      HomeMenuItem(
        id: 'our_assessment',
        title: 'تقييمنا',
        icon: Symbols.verified,
      ),
      HomeMenuItem(
        id: 'child_tests',
        title: 'اختبارات الطفل',
        icon: Symbols.assignment,
      ),
    ],
  ),
  HomeMenuSection(
    id: 'support',
    title: 'الدعم',
    accentColor: AppColors.error,
    layout: HomeSectionLayout.supportList,
    panelColor: AppColors.surfaceContainer,
    items: [
      HomeMenuItem(
        id: 'problem_solving',
        title: 'حل المشكلات',
        icon: Symbols.build,
      ),
      HomeMenuItem(
        id: 'behavioral_consultations',
        title: 'استشارات سلوكية',
        icon: Symbols.support_agent,
        children: [
          HomeMenuItem(
            id: 'paid_consultations',
            title: 'الاستشارات السلوكية والأسرية لطفلك المدفوعة',
            icon: Symbols.payments,
          ),
        ],
      ),
      HomeMenuItem(
        id: 'common_problems',
        title: 'مشاكل الأطفال الشائعة',
        icon: Symbols.warning,
      ),
    ],
  ),
  HomeMenuSection(
    id: 'library',
    title: 'مكتبة المحتوى',
    accentColor: AppColors.primaryDim,
    layout: HomeSectionLayout.contentGrid,
    items: [
      HomeMenuItem(id: 'activities', title: 'الأنشطة', icon: Symbols.sports_esports,
          cardColor: AppColors.trackExerciseLight, iconColor: AppColors.trackExerciseGreen),
      HomeMenuItem(id: 'library_books', title: 'المكتبة', icon: Symbols.folder,
          cardColor: AppColors.trackLibraryLight, iconColor: AppColors.trackLibraryBlue),
      HomeMenuItem(id: 'nature_sounds', title: 'صوت الطبيعة', icon: Symbols.park,
          cardColor: AppColors.trackExerciseLight, iconColor: AppColors.trackExerciseGreen),
      HomeMenuItem(id: 'calm_music', title: 'موسيقى هادئة', icon: Symbols.music_note,
          cardColor: AppColors.trackLibraryLight, iconColor: AppColors.trackLibraryBlue),
      HomeMenuItem(id: 'lullabies', title: 'تهويدات', icon: Symbols.bedtime,
          cardColor: AppColors.trackVisualLight, iconColor: AppColors.trackVisualPurple),
    ],
  ),
  HomeMenuSection(
    id: 'community',
    title: 'المجتمع',
    accentColor: AppColors.secondary,
    layout: HomeSectionLayout.communityTiles,
    panelColor: AppColors.secondaryContainer,
    items: [
      HomeMenuItem(id: 'mothers_club', title: 'نادي الأمهات', icon: Symbols.groups),
      HomeMenuItem(id: 'faq', title: 'أسئلة وأجوبة', icon: Symbols.quiz),
      HomeMenuItem(id: 'complaints', title: 'الشكاوى', icon: Symbols.feedback),
      HomeMenuItem(id: 'suggestions', title: 'الاقتراحات', icon: Symbols.lightbulb),
    ],
  ),
];

HomeMenuSection? homeSectionById(String id) {
  for (final section in homeMenuSections) {
    if (section.id == id) return section;
  }
  return null;
}

HomeMenuItem? homeMenuItemById(String id) {
  HomeMenuItem? search(List<HomeMenuItem> items) {
    for (final item in items) {
      if (item.id == id) return item;
      final child = search(item.children);
      if (child != null) return child;
    }
    return null;
  }

  for (final section in homeMenuSections) {
    final found = search(section.items);
    if (found != null) return found;
  }
  return null;
}

String homeMenuItemTitle(String id) => homeMenuItemById(id)?.title ?? id;
