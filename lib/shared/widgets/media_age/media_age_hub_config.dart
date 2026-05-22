import 'package:flutter/material.dart';

/// إعدادات شاشة المحور العمري (تمارين / أنشطة) — tamareen-ansheta.
class MediaAgeHubConfig {
  const MediaAgeHubConfig({
    required this.kindLabel,
    required this.listSectionTitle,
    required this.progressTitle,
    required this.scaffoldBackground,
    required this.accentColor,
    required this.featuredSubtitleFallback,
  });

  /// «تمارين» أو «أنشطة»
  final String kindLabel;
  final String listSectionTitle;
  final String progressTitle;
  final Color scaffoldBackground;
  final Color accentColor;
  final String featuredSubtitleFallback;

  static const exercises = MediaAgeHubConfig(
    kindLabel: 'تمارين',
    listSectionTitle: 'قائمة التمارين',
    progressTitle: 'تقدم طفلك',
    scaffoldBackground: Color(0xFFF8F9FA),
    accentColor: Color(0xFF00AFAA),
    featuredSubtitleFallback: 'تمارين مناسبة لعمر طفلك — شاهدي وطبّقي بهدوء.',
  );

  static const activities = MediaAgeHubConfig(
    kindLabel: 'أنشطة',
    listSectionTitle: 'قائمة الأنشطة',
    progressTitle: 'تقدم النشاط',
    scaffoldBackground: Color(0xFFFFF8F3),
    accentColor: Color(0xFFF1758E),
    featuredSubtitleFallback: 'لعب إبداعي ومشاركة ممتعة مع طفلك.',
  );
}
