import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: AppShadows.soft,
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

class _CommunityTile extends StatefulWidget {
  const _CommunityTile({required this.item, required this.onTap});

  final HomeMenuItem item;
  final VoidCallback onTap;

  @override
  State<_CommunityTile> createState() => _CommunityTileState();
}

class _CommunityTileState extends State<_CommunityTile> {
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

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 85)
            : const Duration(milliseconds: 200),
        curve: _pressed ? Curves.easeIn : Curves.elasticOut,
        transform: Matrix4.identity()
          ..translate(0.0, _pressed ? 3.0 : 0.0)
          ..scale(_pressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
            width: 2,
          ),
          boxShadow: _pressed ? AppShadows.soft : AppShadows.clayLift,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.04),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.item.icon,
                color: AppColors.secondary,
                size: 22,
                fill: 1,
              ),
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
            Icon(
              Symbols.chevron_left,
              size: 20,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}
