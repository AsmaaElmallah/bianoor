import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/prefs_service.dart';
import '../../../subscription/presentation/widgets/subscribe_banner.dart';
import '../../../timeline/presentation/widgets/timeline_home_card.dart';
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

    // Room for the glass bar + the raised chat orb so the last section stays readable.
    final bottomPad = 112 + MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPad),
      children: [
        HomeHeroCard(babyName: babyName),
        const SizedBox(height: 16),
        const SubscribeBanner(),
        const TimelineHomeCard(),
        const SizedBox(height: 16),
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

    final bottomPad = 112 + MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: bottomPad, top: 4),
      children: [
        HomeSectionBlock(section: section),
      ],
    );
  }
}
