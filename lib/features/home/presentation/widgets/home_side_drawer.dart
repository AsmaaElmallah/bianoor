import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/notifications_screen.dart';
import '../../../subscription/application/premium_access.dart';
import '../../domain/home_menu_data.dart';
import '../../domain/home_menu_item.dart';
import '../home_navigation.dart';

/// Arena-style edge drawer (full-height, flush to start edge in RTL).
class HomeSideDrawer extends ConsumerWidget {
  const HomeSideDrawer({super.key});

  static Future<void> open(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'القائمة',
      barrierColor: AppColors.onSurface.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, __) => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: HomeSideDrawer(),
      ),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        // RTL: panel sits on the right → slide from +X. LTR: from -X.
        final begin = Offset(rtl ? 1 : -1, 0);
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width * 0.78;
    final start = homeSectionById('start_learning');
    final support = homeSectionById('support');
    final communityExtras = homeSectionById('community')?.items ?? const <HomeMenuItem>[];

    return Material(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      child: SizedBox(
        width: width.clamp(260.0, 320.0),
        height: MediaQuery.sizeOf(context).height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: BorderDirectional(
              end: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.9)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Text(
                          'ب',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'القائمة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Symbols.close, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                    children: [
                      _DrawerTile(
                        title: 'الإشعارات',
                        icon: Symbols.notifications,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                      _DrawerTile(
                        title: 'مدّي الاشتراك',
                        icon: Symbols.workspace_premium,
                        accent: AppColors.secondary,
                        onTap: () {
                          Navigator.of(context).pop();
                          openPlansForLessons(context, ref);
                        },
                      ),
                      if (start != null) ...[
                        const SizedBox(height: 6),
                        _SectionLabel(start.title),
                        for (final item in start.items)
                          _DrawerExpandable(
                            item: item,
                            onLeaf: (leaf) {
                              Navigator.of(context).pop();
                              openHomeMenuItem(context, leaf);
                            },
                          ),
                      ],
                      if (support != null) ...[
                        const SizedBox(height: 10),
                        _SectionLabel(support.title),
                        for (final item in support.items)
                          _DrawerExpandable(
                            item: item,
                            onLeaf: (leaf) {
                              Navigator.of(context).pop();
                              openHomeMenuItem(context, leaf);
                            },
                          ),
                      ],
                      if (communityExtras.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const _SectionLabel('المزيد'),
                        for (final item in communityExtras)
                          _DrawerTile(
                            title: item.title,
                            icon: item.icon,
                            onTap: () {
                              Navigator.of(context).pop();
                              openHomeMenuItem(context, item);
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.accent,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: color, weight: 600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _DrawerExpandable extends StatelessWidget {
  const _DrawerExpandable({required this.item, required this.onLeaf});

  final HomeMenuItem item;
  final ValueChanged<HomeMenuItem> onLeaf;

  @override
  Widget build(BuildContext context) {
    if (!item.hasChildren) {
      return _DrawerTile(
        title: item.title,
        icon: item.icon,
        onTap: () => onLeaf(item),
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsetsDirectional.only(start: 8),
        leading: Icon(item.icon, color: AppColors.primary, weight: 600),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        children: [
          for (final child in item.children)
            _DrawerExpandable(item: child, onLeaf: onLeaf),
        ],
      ),
    );
  }
}
