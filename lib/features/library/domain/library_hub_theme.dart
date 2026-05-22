import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'library_media_catalog.dart';

/// ثيم شاشة المشغّل حسب الفئة (مطابق لتصاميم 3d_*).
class LibraryHubTheme {
  const LibraryHubTheme({
    required this.scaffoldBackground,
    required this.heroSubtitle,
    required this.titleColor,
    required this.accentColor,
    required this.progressGradient,
    required this.showNatureChips,
    required this.listSectionTitle,
    required this.listStyle,
  });

  final Color scaffoldBackground;
  final String heroSubtitle;
  final Color titleColor;
  final Color accentColor;
  final List<Color> progressGradient;
  final bool showNatureChips;
  final String listSectionTitle;
  final LibraryHubListStyle listStyle;

  static LibraryHubTheme forCategory(LibraryMediaCategoryId id) {
    switch (id) {
      case LibraryMediaCategoryId.natureSounds:
        return const LibraryHubTheme(
          scaffoldBackground: Color(0xFFE8F5E9),
          heroSubtitle: 'استرخِ مع ألحان الطبيعة الهادئة',
          titleColor: Color(0xFF00668A),
          accentColor: Color(0xFF735C00),
          progressGradient: [Color(0xFF41AFE4), Color(0xFF00AFAA)],
          showNatureChips: true,
          listSectionTitle: '',
          listStyle: LibraryHubListStyle.hidden,
        );
      case LibraryMediaCategoryId.lullabies:
        return const LibraryHubTheme(
          scaffoldBackground: Color(0xFFF3E8FF),
          heroSubtitle: 'وقت الراحة الصغير...',
          titleColor: Color(0xFF772953),
          accentColor: Color(0xFF95416C),
          progressGradient: [Color(0xFFFA95C4), Color(0xFF95416C)],
          showNatureChips: false,
          listSectionTitle: 'المزيد من الأغاني',
          listStyle: LibraryHubListStyle.rich,
        );
      case LibraryMediaCategoryId.calmMusic:
        return const LibraryHubTheme(
          scaffoldBackground: Color(0xFFF8F9FA),
          heroSubtitle: 'وقت النوم المريح لصغيرك',
          titleColor: Color(0xFF00668A),
          accentColor: Color(0xFF00668A),
          progressGradient: [Color(0xFF6BBEEB), Color(0xFF00668A)],
          showNatureChips: false,
          listSectionTitle: 'التالي في القائمة',
          listStyle: LibraryHubListStyle.queue,
        );
    }
  }
}

enum LibraryHubListStyle { hidden, rich, queue }

/// شرائح تصنيف أصوات الطبيعة.
enum NatureSoundChip {
  rain('مطر', Symbols.water_drop),
  forest('غابة', Symbols.forest),
  ocean('محيط', Symbols.tsunami),
  wind('رياح', Symbols.air);

  const NatureSoundChip(this.label, this.icon);
  final String label;
  final IconData icon;
}
