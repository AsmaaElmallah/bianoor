import 'package:flutter/material.dart';

import '../../domain/home_menu_item.dart';
import '../home_navigation.dart';
import 'home_community_tiles.dart';
import 'home_content_grid.dart';
import 'home_list_panel.dart';
import 'home_pastel_grid.dart';
import 'home_section_heading.dart';
import 'home_shortcut_strip.dart';

class HomeSectionBlock extends StatelessWidget {
  const HomeSectionBlock({
    super.key,
    required this.section,
  });

  final HomeMenuSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeading(
          title: section.title,
          accentColor: section.accentColor,
        ),
        _SectionBody(section: section),
      ],
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section});

  final HomeMenuSection section;

  void _onTap(BuildContext context, HomeMenuItem item) {
    openHomeMenuItem(context, item);
  }

  @override
  Widget build(BuildContext context) {
    switch (section.layout) {
      case HomeSectionLayout.shortcutStrip:
        return HomeShortcutStrip(
          items: section.items,
          onItemTap: (item) => _onTap(context, item),
        );
      case HomeSectionLayout.pastelGrid:
        return HomePastelGrid(
          items: section.items,
          onItemTap: (item) => _onTap(context, item),
        );
      case HomeSectionLayout.listPanel:
        return HomeListPanel(
          items: section.items,
          onItemTap: (item) => _onTap(context, item),
        );
      case HomeSectionLayout.supportList:
        return HomeListPanel(
          items: section.items,
          panelColor: section.panelColor,
          accentIcons: true,
          showChevron: false,
          onItemTap: (item) => _onTap(context, item),
        );
      case HomeSectionLayout.contentGrid:
        return HomeContentGrid(
          items: section.items,
          onItemTap: (item) => _onTap(context, item),
        );
      case HomeSectionLayout.communityTiles:
        return HomeCommunityTiles(
          items: section.items,
          panelColor: section.panelColor,
          onItemTap: (item) => _onTap(context, item),
        );
    }
  }
}
