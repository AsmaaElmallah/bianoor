import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_art.dart';

/// Layout style used when rendering a home section.
enum HomeSectionLayout {
  shortcutStrip,
  pastelGrid,
  listPanel,
  supportList,
  contentGrid,
  communityTiles,
}

/// A navigable item on the home dashboard or inside a section tab.
class HomeMenuItem {
  const HomeMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.art,
    this.subtitle,
    this.cardColor,
    this.iconColor,
    this.premium = false,
    this.children = const [],
  });

  final String id;
  final String title;
  final IconData icon;

  /// 3D asset from `AppArt`; [icon] is the fallback.
  final String? art;
  final String? subtitle;
  final Color? cardColor;
  final Color? iconColor;

  /// Lesson content unlocked by a paid plan; shows a lock until one is bought.
  final bool premium;
  final List<HomeMenuItem> children;

  bool get hasChildren => children.isNotEmpty;
}

/// A grouped section on the home dashboard.
class HomeMenuSection {
  const HomeMenuSection({
    required this.id,
    required this.title,
    required this.accentColor,
    required this.layout,
    required this.items,
    this.panelColor,
    this.art,
  });

  final String id;
  final String title;
  final Color accentColor;
  final String? art;
  final HomeSectionLayout layout;
  final List<HomeMenuItem> items;
  final Color? panelColor;
}

/// Bottom navigation tab definition.
class HomeNavTab {
  const HomeNavTab({
    required this.id,
    required this.label,
    required this.icon,
    this.art,
    this.sectionId,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Shown only on the active tab.
  final String? art;

  /// When set, the tab reuses this dashboard section's content.
  final String? sectionId;
}

/// All bottom-nav tabs (order matches the design).
const homeNavTabs = <HomeNavTab>[
  HomeNavTab(id: 'home', label: 'الرئيسية', icon: Symbols.home, art: AppArt.house),
  HomeNavTab(id: 'lessons', label: 'الدروس', icon: Symbols.school, art: AppArt.graduationCap, sectionId: 'lessons'),
  HomeNavTab(id: 'assessment', label: 'التقييم', icon: Symbols.assignment, art: AppArt.clipboard, sectionId: 'assessment'),
  HomeNavTab(id: 'library', label: 'المكتبة', icon: Symbols.menu_book, art: AppArt.books, sectionId: 'library'),
  HomeNavTab(id: 'community', label: 'المجتمع', icon: Symbols.groups, art: AppArt.people, sectionId: 'community'),
];
