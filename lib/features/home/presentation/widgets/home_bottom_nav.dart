import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/home_menu_item.dart';

/// Glass bottom navigation — frosted white blur + warm shadow + pill active indicator.
/// Matches the Lullaby Learning design: glass white/70, blur 24px, rounded-top 3rem.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.center,
  });

  final List<HomeNavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Raised control sitting in the middle of the bar, above the glass.
  final Widget? center;

  /// Puts the glass top a little below the chat orb's midline.
  static const _raise = 36.0;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final midpoint = tabs.length ~/ 2;
    final hasCenter = center != null;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: hasCenter ? _raise : 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.88),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(8, 12, 8, 10 + bottomPad),
                      child: Row(
                        children: [
                          for (var i = 0; i < midpoint; i++)
                            Expanded(child: _item(i)),
                          if (hasCenter) const SizedBox(width: 72),
                          for (var i = midpoint; i < tabs.length; i++)
                            Expanded(child: _item(i)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasCenter) Positioned(top: 0, child: center!),
      ],
    );
  }

  Widget _item(int index) {
    return _NavItem(
      tab: tabs[index],
      isActive: index == currentIndex,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final HomeNavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: AppRadius.brFull,
            border: isActive
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                    child: child,
                  ),
                  child: isActive && widget.tab.art != null
                      ? Image.asset(
                          widget.tab.art!,
                          key: const ValueKey('art'),
                          width: 32,
                          height: 32,
                        )
                      : Icon(
                          widget.tab.icon,
                          key: const ValueKey('icon'),
                          color: isActive
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontFamily: 'XPNiloofar',
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.65),
                ),
                child: Text(widget.tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
