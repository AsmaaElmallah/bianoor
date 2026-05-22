import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/home_menu_item.dart';

class HomeContentGrid extends StatelessWidget {
  const HomeContentGrid({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  final List<HomeMenuItem> items;
  final ValueChanged<HomeMenuItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ContentCard(item: item, onTap: () => onItemTap(item));
      },
    );
  }
}

class _ContentCard extends StatefulWidget {
  const _ContentCard({required this.item, required this.onTap});

  final HomeMenuItem item;
  final VoidCallback onTap;

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
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
    final bg = widget.item.cardColor ?? AppColors.primaryContainer;
    final iconColor = widget.item.iconColor ?? AppColors.primary;
    final depthColor = Color.lerp(bg, Colors.black, 0.12) ?? bg;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 220),
        curve: _pressed ? Curves.easeIn : Curves.elasticOut,
        transform: Matrix4.identity()
          ..translate(0.0, _pressed ? 3.0 : 0.0)
          ..scale(_pressed ? 0.96 : 1.0),
        transformAlignment: Alignment.center,
        child: Stack(
          children: [
            // Depth block
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: AnimatedContainer(
                duration: _pressed
                    ? const Duration(milliseconds: 90)
                    : const Duration(milliseconds: 180),
                height: _pressed ? 0 : 5,
                decoration: BoxDecoration(
                  color: depthColor,
                  borderRadius: AppRadius.brMd,
                ),
              ),
            ),

            // Card face
            Container(
              margin: EdgeInsets.only(bottom: _pressed ? 0 : 5),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: AppRadius.brMd,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: _pressed
                    ? []
                    : [
                        BoxShadow(
                          color: depthColor.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.item.icon,
                        color: iconColor, size: 24, fill: 1),
                  ),
                  Text(
                    widget.item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
