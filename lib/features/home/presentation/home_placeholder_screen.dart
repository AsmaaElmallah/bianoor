import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/floating_decoration.dart';

class HomePlaceholderScreen extends ConsumerStatefulWidget {
  const HomePlaceholderScreen({super.key});

  @override
  ConsumerState<HomePlaceholderScreen> createState() => _HomePlaceholderScreenState();
}

class _HomePlaceholderScreenState extends ConsumerState<HomePlaceholderScreen> {
  int _currentTab = 0;

  static const _tabs = <_NavItem>[
    _NavItem(icon: Symbols.home, label: 'الرئيسية'),
    _NavItem(icon: Symbols.menu_book, label: 'الدروس'),
    _NavItem(icon: Symbols.auto_graph, label: 'النمو'),
    _NavItem(icon: Symbols.settings, label: 'الإعدادات'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final babyName = ref.watch(prefsServiceProvider).getBabyName() ?? 'صغيرك';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const AppLogoAvatar(size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أهلاً بك في',
                              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            Text(
                              'بيانور',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: AppRadius.brFull,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1,
                          ),
                          boxShadow: AppShadows.clayLift,
                        ),
                        child: IconButton(
                          icon: const Icon(Symbols.notifications, color: AppColors.primary, fill: 1),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: AppRadius.brLg,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: AppShadows.clayLift,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingDecoration(
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 176,
                                    height: 176,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient,
                                    ),
                                  ),
                                  Container(
                                    width: 148,
                                    height: 148,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      shape: BoxShape.circle,
                                      boxShadow: AppShadows.clayLift,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Symbols.celebration,
                                      color: AppColors.primary,
                                      size: 72,
                                      fill: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'مرحباً بـ $babyName!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'يا له من يوم رائع لبدء رحلة جديدة!\nالدروس التفاعلية والأنشطة قادمة قريباً.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: AppRadius.brFull,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Symbols.construction,
                                    color: AppColors.onSecondaryContainer,
                                    size: 16,
                                    fill: 1,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'قيد التطوير',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: AppColors.onSecondaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        items: _tabs,
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.48),
              width: 1,
            ),
            boxShadow: [
              ...AppShadows.bottomNav,
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.55),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return InkWell(
                onTap: () => onTap(i),
                borderRadius: AppRadius.brLg,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                        fill: isActive ? 1 : 0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
