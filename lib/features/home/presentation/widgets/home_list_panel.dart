import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../domain/home_menu_item.dart';

class HomeListPanel extends StatelessWidget {
  const HomeListPanel({
    super.key,
    required this.items,
    required this.onItemTap,
    this.panelColor,
    this.accentIcons = false,
    this.showChevron = true,
  });

  final List<HomeMenuItem> items;
  final ValueChanged<HomeMenuItem> onItemTap;
  final Color? panelColor;
  final bool accentIcons;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panelColor ?? AppColors.surfaceContainerLowest,
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _ListRow(
                item: item,
                accentIcons: accentIcons,
                showChevron: showChevron,
                onTap: () => onItemTap(item),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.35),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.item,
    required this.onTap,
    required this.accentIcons,
    required this.showChevron,
  });

  final HomeMenuItem item;
  final VoidCallback onTap;
  final bool accentIcons;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = accentIcons ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (showChevron)
                Icon(
                  Icons.chevron_left,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 22,
                ),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(item.icon, color: iconColor, size: 24, fill: 1),
            ],
          ),
        ),
      ),
    );
  }
}
