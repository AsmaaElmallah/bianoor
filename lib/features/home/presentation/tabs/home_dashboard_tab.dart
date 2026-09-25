import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/prefs_service.dart';
import '../../domain/home_menu_data.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_section_block.dart';

/// Sections reachable only from the bottom navigation bar.
const _navOnlySectionIds = {'community'};

class HomeDashboardTab extends ConsumerWidget {
  const HomeDashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyName = ref.watch(prefsServiceProvider).getBabyName() ?? 'طفلك';
    final sections = homeMenuSections
        .where((s) => !_navOnlySectionIds.contains(s.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        HomeHeroCard(babyName: babyName),
        const SizedBox(height: 24),
        for (var i = 0; i < sections.length; i++) ...[
          HomeSectionBlock(section: sections[i]),
          if (i < sections.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class HomeSectionTab extends StatelessWidget {
  const HomeSectionTab({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final section = homeSectionById(sectionId);
    if (section == null) {
      return const Center(child: Text('القسم غير متوفر'));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      children: [
        HomeSectionBlock(section: section),
      ],
    );
  }
}
