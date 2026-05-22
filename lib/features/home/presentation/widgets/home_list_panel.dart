import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: AppShadows.card,
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
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
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

class _ListRow extends StatefulWidget {
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
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.selectionClick();
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.accentIcons
        ? AppColors.error
        : (widget.item.iconColor ?? AppColors.primary);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 200),
        curve: _pressed ? Curves.easeIn : Curves.easeOut,
        color: _pressed
            ? AppColors.surfaceContainerLow
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (widget.showChevron)
                Icon(
                  Icons.chevron_left,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 22,
                ),

              // Icon circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(widget.item.icon,
                    color: iconColor, size: 20, fill: 1),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  widget.item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
