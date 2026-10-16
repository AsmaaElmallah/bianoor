import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/floating_widget.dart';
import '../../../../shared/widgets/icon_3d.dart';
import '../../../subscription/application/premium_access.dart';
import '../../domain/home_menu_item.dart';

class HomePastelGrid extends StatelessWidget {
  const HomePastelGrid({
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
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _PastelCard(
          item: item,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}

class _PastelCard extends ConsumerStatefulWidget {
  const _PastelCard({required this.item, required this.onTap});

  final HomeMenuItem item;
  final VoidCallback onTap;

  @override
  ConsumerState<_PastelCard> createState() => _PastelCardState();
}

class _PastelCardState extends ConsumerState<_PastelCard> {
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
    final locked = widget.item.premium && ref.watch(unlockedLessonDaysProvider).valueOrNull == 0;

    // Depth block color — slightly darker than bg
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
            // Clay depth block
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
              clipBehavior: Clip.hardEdge,
              margin: EdgeInsets.only(bottom: _pressed ? 0 : 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topEnd,
                  end: AlignmentDirectional.bottomStart,
                  colors: [
                    Color.lerp(bg, Colors.white, 0.35)!,
                    bg,
                    Color.lerp(bg, iconColor, 0.14)!,
                  ],
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
                          color: depthColor.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: AlignmentDirectional.topStart,
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.9),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                    FloatingWidget(
                                      amplitude: 1.5,
                                      duration: Duration(milliseconds: 2600 + widget.item.id.length * 90),
                                      child: Icon3D(
                                        art: widget.item.art,
                                        icon: widget.item.icon,
                                        color: iconColor,
                                        size: 58,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (locked)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Symbols.lock,
                              size: 16,
                              fill: 1,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
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
