import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_art.dart';
import '../../../core/theme/app_colors.dart';
import 'home_menu_item.dart';

/// Track-themed lesson card colors — warmer & more vibrant.
class HomeLessonColors {
  HomeLessonColors._();

  // Green + gold to match the Quran art.
  static const quranBg   = Color(0xFFE2F1E3);
  static const quranIcon = Color(0xFF3E8E5A);

  // Sky blue lets the colourful abacus pop.
  static const mathBg    = Color(0xFFE2EEFF);
  static const mathIcon  = Color(0xFF4A7FD6);

  static const visualBg  = AppColors.trackVisualLight;  // #EFE3FF purple tint
  static const visualIcon= AppColors.trackVisualPurple; // #9C6FD6

  static const emotionalBg  = Color(0xFFFFE5EE);
  static const emotionalIcon = Color(0xFFD45D7A);
}

const homeMenuSections = <HomeMenuSection>[
  HomeMenuSection(
    id: 'start_learning',
    art: AppArt.sparkles,
    title: 'ابدأ التعلم',
    accentColor: AppColors.primary,
    layout: HomeSectionLayout.shortcutStrip,
    items: [
      HomeMenuItem(
        id: 'courses', art: AppArt.graduationCap,
        title: 'الدورات',
        icon: Symbols.school,
      ),
      HomeMenuItem(
        id: 'assessment', art: AppArt.clipboard,
        title: 'التقييم',
        icon: Symbols.assignment,
        children: [
          HomeMenuItem(
            id: 'mother_assessment', art: AppArt.clipboard,
            title: 'تقييم الأم',
            icon: Symbols.family_restroom,
            children: [
              HomeMenuItem(id: 'aptitude_test', art: AppArt.brain, title: 'اختبار القدرات', icon: Symbols.psychology),
              HomeMenuItem(id: 'skills_test', art: AppArt.checkMark, title: 'اختبار المهارات', icon: Symbols.fact_check),
              HomeMenuItem(id: 'interests_test', art: AppArt.palette, title: 'فحص ميول الطفل وشغفه', icon: Symbols.interests),
            ],
          ),
          HomeMenuItem(
            id: 'our_assessment', art: AppArt.star,
            title: 'تقييمنا',
            icon: Symbols.verified,
          ),
          HomeMenuItem(
            id: 'child_tests', art: AppArt.memo,
            title: 'اختبارات الطفل',
            icon: Symbols.assignment,
          ),
        ],
      ),
      HomeMenuItem(
        id: 'curriculum', art: AppArt.books,
        title: 'المنهج',
        icon: Symbols.menu_book,
        children: [
          HomeMenuItem(
            id: 'curriculum_about', art: AppArt.openBook,
            title: 'ما هو المنهج؟ (أهدافه وأساليبه)',
            icon: Symbols.auto_stories,
          ),
          HomeMenuItem(
            id: 'parent_general_culture', art: AppArt.lightBulb,
            title: 'ثقافة هامة للأمهات / ولي الأمر لطفلك',
            icon: Symbols.groups,
          ),
          HomeMenuItem(
            id: 'parent_health_culture', art: AppArt.stethoscope,
            title: 'الثقافة الصحية',
            icon: Symbols.health_and_safety,
          ),
        ],
      ),
      HomeMenuItem(
        id: 'how_to_teach', art: AppArt.puzzle,
        title: 'كيف أدرّس طفلي؟',
        icon: Symbols.location_on,
      ),
      HomeMenuItem(
        id: 'baby_exercises', art: AppArt.ball,
        title: 'الرياضة',
        icon: Symbols.fitness_center,
      ),
    ],
  ),
  HomeMenuSection(
    id: 'lessons',
    art: AppArt.graduationCap,
    title: 'الدروس',
    accentColor: AppColors.secondary,
    layout: HomeSectionLayout.pastelGrid,
    items: [
      HomeMenuItem(
        id: 'lesson_quran', art: AppArt.quran,
        title: 'القرآن الكريم',
        icon: Symbols.menu_book,
        cardColor: HomeLessonColors.quranBg,
        iconColor: HomeLessonColors.quranIcon,
        premium: true,
      ),
      HomeMenuItem(
        id: 'lesson_math', art: AppArt.abacus,
        title: 'الحساب النقطي',
        icon: Symbols.grid_on,
        cardColor: HomeLessonColors.mathBg,
        iconColor: HomeLessonColors.mathIcon,
        premium: true,
      ),
      HomeMenuItem(
        id: 'lesson_visual', art: AppArt.eye,
        title: 'التحفيز البصري',
        icon: Symbols.visibility,
        cardColor: HomeLessonColors.visualBg,
        iconColor: HomeLessonColors.visualIcon,
        premium: true,
      ),
      HomeMenuItem(
        id: 'lesson_emotional', art: AppArt.heart,
        title: 'الذكاء العاطفي',
        icon: Symbols.favorite,
        cardColor: HomeLessonColors.emotionalBg,
        iconColor: HomeLessonColors.emotionalIcon,
        premium: true,
      ),
    ],
  ),
  HomeMenuSection(
    id: 'support',
    art: AppArt.headphone,
    title: 'الدعم',
    accentColor: AppColors.error,
    layout: HomeSectionLayout.supportList,
    panelColor: AppColors.surfaceContainer,
    items: [
      HomeMenuItem(
        id: 'problem_solving', art: AppArt.tools,
        title: 'حل المشكلات',
        icon: Symbols.build,
      ),
      HomeMenuItem(
        id: 'behavioral_consultations', art: AppArt.headphone,
        title: 'استشارات سلوكية',
        icon: Symbols.support_agent,
        children: [
          HomeMenuItem(
            id: 'paid_consultations', art: AppArt.gem,
            title: 'الاستشارات السلوكية والأسرية لطفلك المدفوعة',
            icon: Symbols.payments,
          ),
        ],
      ),
      HomeMenuItem(
        id: 'common_problems', art: AppArt.thinking,
        title: 'مشاكل الأطفال الشائعة',
        icon: Symbols.warning,
      ),
    ],
  ),
  HomeMenuSection(
    id: 'library',
    art: AppArt.books,
    title: 'مكتبة المحتوى',
    accentColor: AppColors.primaryDim,
    layout: HomeSectionLayout.contentGrid,
    items: [
      HomeMenuItem(id: 'activities', art: AppArt.teddyBear, title: 'الأنشطة', icon: Symbols.sports_esports,
          cardColor: AppColors.trackExerciseLight, iconColor: AppColors.trackExerciseGreen),
      HomeMenuItem(id: 'nature_sounds', art: AppArt.tree, title: 'صوت الطبيعة', icon: Symbols.park,
          cardColor: AppColors.trackExerciseLight, iconColor: AppColors.trackExerciseGreen),
      HomeMenuItem(id: 'calm_music', art: AppArt.musicNotes, title: 'موسيقى هادئة', icon: Symbols.music_note,
          cardColor: AppColors.trackLibraryLight, iconColor: AppColors.trackLibraryBlue),
      HomeMenuItem(id: 'lullabies', art: AppArt.moon, title: 'تهويدات', icon: Symbols.bedtime,
          cardColor: AppColors.trackVisualLight, iconColor: AppColors.trackVisualPurple),
    ],
  ),
  HomeMenuSection(
    id: 'community',
    art: AppArt.people,
    title: 'المجتمع',
    accentColor: AppColors.secondary,
    layout: HomeSectionLayout.communityTiles,
    panelColor: AppColors.secondaryContainer,
    items: [
      HomeMenuItem(id: 'mothers_club', art: AppArt.people, title: 'نادي الأمهات', icon: Symbols.groups),
      HomeMenuItem(id: 'faq', art: AppArt.question, title: 'أسئلة وأجوبة', icon: Symbols.quiz),
      HomeMenuItem(id: 'complaints', art: AppArt.megaphone, title: 'الشكاوى', icon: Symbols.feedback),
      HomeMenuItem(id: 'suggestions', art: AppArt.lightBulb, title: 'الاقتراحات', icon: Symbols.lightbulb),
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
