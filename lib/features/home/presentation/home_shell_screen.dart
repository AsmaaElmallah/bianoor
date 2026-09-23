import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../domain/home_menu_item.dart';
import 'tabs/home_dashboard_tab.dart';
import 'tabs/library_tab.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_header.dart';

/// Selected bottom-nav tab; menu items can switch tabs (e.g. «المكتبة»).
final homeTabIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

class HomeShellScreen extends ConsumerWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(homeTabIndexProvider);
    final showHeader = currentTab == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Column(
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: const HomeHeader(),
                  ),
                if (showHeader) const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: IndexedStack(
                      index: currentTab,
                      children: [
                        const HomeDashboardTab(),
                        HomeSectionTab(sectionId: homeNavTabs[1].sectionId!),
                        HomeSectionTab(sectionId: homeNavTabs[2].sectionId!),
                        const LibraryTab(),
                        HomeSectionTab(sectionId: homeNavTabs[4].sectionId!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        tabs: homeNavTabs,
        currentIndex: currentTab,
        onTap: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
      ),
    );
  }
}
