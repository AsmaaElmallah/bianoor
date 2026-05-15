import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../domain/home_menu_item.dart';
import 'tabs/home_dashboard_tab.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_header.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final showHeader = _currentTab == 0;

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
                    padding: EdgeInsets.symmetric(horizontal: showHeader ? 24 : 24),
                    child: IndexedStack(
                      index: _currentTab,
                      children: [
                        const HomeDashboardTab(),
                        HomeSectionTab(sectionId: homeNavTabs[1].sectionId!),
                        HomeSectionTab(sectionId: homeNavTabs[2].sectionId!),
                        HomeSectionTab(sectionId: homeNavTabs[3].sectionId!),
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
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
      ),
    );
  }
}
