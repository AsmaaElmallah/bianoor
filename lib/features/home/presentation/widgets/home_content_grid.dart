import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/icon_3d.dart';
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
    final depthColor = Color.lerp(bg, iconColor, 0.45) ?? bg;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: Duration(milliseconds: _pressed ? 90 : 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Stack(
          fit: StackFit.expand,
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(bg, Colors.white, 0.4)!, bg],
                ),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon3D(
                    art: widget.item.art,
                    icon: widget.item.icon,
                    color: iconColor,
                    size: 54,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.item.title,
                    textAlign: TextAlign.center,
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
      ),
    );
  }
}
