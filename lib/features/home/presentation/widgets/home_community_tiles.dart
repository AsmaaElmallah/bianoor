import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../domain/home_menu_item.dart';

class HomeCommunityTiles extends StatelessWidget {
  const HomeCommunityTiles({
    super.key,
    required this.items,
    required this.onItemTap,
    this.panelColor,
  });

  final List<HomeMenuItem> items;
  final ValueChanged<HomeMenuItem> onItemTap;
  final Color? panelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (panelColor ?? AppColors.secondaryContainer).withValues(alpha: 0.45),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < items.length - 1 ? 8 : 0),
            child: _CommunityTile(item: item, onTap: () => onItemTap(item)),
          );
        }),
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({required this.item, required this.onTap});

  final HomeMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            boxShadow: AppShadows.soft,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(item.icon, color: AppColors.secondary, size: 24, fill: 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
