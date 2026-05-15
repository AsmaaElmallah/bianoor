import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import 'home_menu_item.dart';

/// Pastel tints for lesson cards (from the design reference).
class HomeLessonColors {
  HomeLessonColors._();

  static const quran = Color(0xFFD4EDF7);
  static const math = Color(0xFFF5E6B8);
  static const visual = Color(0xFFF0EDD8);
  static const emotional = Color(0xFFF8D4DC);
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
            title: 'ما هو المنهج؟ (أهدافه وأساليبه)',
            icon: Symbols.auto_stories,
          ),
          HomeMenuItem(
            id: 'mother_health_culture',
            title: 'ثقافة هامة للأمهات للرعاية الصحية بطفلك',
            icon: Symbols.health_and_safety,
          ),
        ],
      ),
      HomeMenuItem(
        id: 'how_to_teach',
        title: 'كيف أدرس طفلي',
        icon: Symbols.location_on,
      ),
      HomeMenuItem(
        id: 'apply_activities',
        title: 'تطبيق الأنشطة',
        icon: Symbols.extension,
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
        cardColor: HomeLessonColors.quran,
        iconColor: AppColors.tertiary,
      ),
      HomeMenuItem(
        id: 'lesson_math',
        title: 'الحساب النقطي',
        icon: Symbols.grid_on,
        cardColor: HomeLessonColors.math,
        iconColor: AppColors.secondaryDim,
      ),
      HomeMenuItem(
        id: 'lesson_visual',
        title: 'التحفيز البصري',
        icon: Symbols.visibility,
        cardColor: HomeLessonColors.visual,
        iconColor: AppColors.onSurfaceVariant,
      ),
      HomeMenuItem(
        id: 'lesson_emotional',
        title: 'الذكاء العاطفي',
        icon: Symbols.favorite,
        cardColor: HomeLessonColors.emotional,
        iconColor: AppColors.secondary,
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
      HomeMenuItem(id: 'activities', title: 'الأنشطة', icon: Symbols.sports_esports),
      HomeMenuItem(id: 'library_books', title: 'المكتبة', icon: Symbols.folder),
      HomeMenuItem(id: 'nature_sounds', title: 'سمعيات الطبيعة', icon: Symbols.park),
      HomeMenuItem(id: 'calm_music', title: 'موسيقى هادئة', icon: Symbols.music_note),
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
