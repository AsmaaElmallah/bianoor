import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// إعدادات مسار الدروس لكل مادة (حساب / بصري / عاطفي).
class CurriculumJourneyConfig {
  const CurriculumJourneyConfig({
    required this.journeyTitle,
    required this.journeyHeroTitle,
    required this.journeyHeroSubtitle,
    required this.headerIcon,
    required this.lessonCount,
    required this.maxLessonNumber,
    required this.lastNewContentDay,
    required this.reviewCycleStartDay,
    required this.lessonDaysPath,
    required this.playerPath,
  });

  final String journeyTitle;
  final String journeyHeroTitle;
  final String journeyHeroSubtitle;
  final IconData headerIcon;
  final int lessonCount;
  final int maxLessonNumber;
  final int lastNewContentDay;
  final int reviewCycleStartDay;
  final String Function(int lessonNumber) lessonDaysPath;
  final String playerPath;

  String playerPathForLesson(int lessonNumber) => '$playerPath?lesson=$lessonNumber';

  String lessonLabel(int lessonNumber) => 'الدرس $lessonNumber';
}

CurriculumJourneyConfig mathJourneyConfig() => CurriculumJourneyConfig(
      journeyTitle: 'رحلة الحساب النقطي',
      journeyHeroTitle: 'منهج الحساب الذهني',
      journeyHeroSubtitle: '٢٥ درساً — من البداية الذكية حتى التكرار',
      headerIcon: Symbols.calculate,
      lessonCount: 25,
      maxLessonNumber: 25,
      lastNewContentDay: 160,
      reviewCycleStartDay: 161,
      lessonDaysPath: (n) => '/home/math/$n',
      playerPath: '/home/math/player',
    );

CurriculumJourneyConfig visualJourneyConfig() => CurriculumJourneyConfig(
      journeyTitle: 'رحلة التحفيز البصري',
      journeyHeroTitle: 'التحفيز البصري',
      journeyHeroSubtitle: '٣٠ درساً — شرائح متدرجة حسب العمر',
      headerIcon: Symbols.visibility,
      lessonCount: 30,
      maxLessonNumber: 30,
      lastNewContentDay: 185,
      reviewCycleStartDay: 186,
      lessonDaysPath: (n) => '/home/visual/$n',
      playerPath: '/home/visual/player',
    );

CurriculumJourneyConfig emotionalJourneyConfig() => CurriculumJourneyConfig(
      journeyTitle: 'رحلة الذكاء العاطفي',
      journeyHeroTitle: 'الذكاء العاطفي',
      journeyHeroSubtitle: '١٧ درساً — المشاعر والتفاعل',
      headerIcon: Symbols.favorite,
      lessonCount: 17,
      maxLessonNumber: 17,
      lastNewContentDay: 120,
      reviewCycleStartDay: 121,
      lessonDaysPath: (n) => '/home/emotional/$n',
      playerPath: '/home/emotional/player',
    );
