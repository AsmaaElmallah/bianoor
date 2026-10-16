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
    required this.arenaHeroColor,
    this.arenaIconWell,
    this.arenaBadge,
    this.arenaTags = const [],
    this.arenaShowContrastTiles = false,
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

  /// Arena feature-card background.
  final Color arenaHeroColor;
  final Color? arenaIconWell;
  final String? arenaBadge;
  final List<String> arenaTags;
  final bool arenaShowContrastTiles;

  String lessonLabel(int lessonNumber) => 'الدرس $lessonNumber';
}

CurriculumJourneyConfig mathJourneyConfig() => CurriculumJourneyConfig(
      journeyTitle: 'رحلة الحساب النقطي',
      journeyHeroTitle: 'الحساب الذهني',
      journeyHeroSubtitle:
          'أناشيد وألعاب أرقام أولى تصنع علاقة ودّ مع الأرقام وتهيّئ التفكير المنطقي.',
      headerIcon: Symbols.calculate,
      lessonCount: 25,
      maxLessonNumber: 25,
      lastNewContentDay: 160,
      reviewCycleStartDay: 161,
      lessonDaysPath: (n) => '/home/math/$n',
      playerPath: '/home/math/player',
      arenaHeroColor: Colors.white,
      arenaIconWell: const Color(0xFF4A7FD6),
      arenaTags: const ['أناشيد ١–١٠', 'ألعاب عدّ'],
    );

CurriculumJourneyConfig visualJourneyConfig() => CurriculumJourneyConfig(
      journeyTitle: 'رحلة التحفيز البصري',
      journeyHeroTitle: 'التحفيز البصري',
      journeyHeroSubtitle:
          'بطاقات بالأبيض والأسود عالية التباين تحفّز شبكية العين والوصلات العصبية.',
      headerIcon: Symbols.visibility,
      lessonCount: 30,
      maxLessonNumber: 30,
      lastNewContentDay: 185,
      reviewCycleStartDay: 186,
      lessonDaysPath: (n) => '/home/visual/$n',
      playerPath: '/home/visual/player',
      arenaHeroColor: const Color(0xFF29223F),
      arenaBadge: '٠ – ٦ شهور',
      arenaShowContrastTiles: true,
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
      arenaHeroColor: Colors.white,
      arenaIconWell: const Color(0xFFE85D8A),
      arenaTags: const ['تمارين تهدئة', 'ربط عاطفي'],
    );
