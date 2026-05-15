import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';

/// Floating Quran + mascot cluster for the tactile player (_1q).
class QuranFloatingHero extends StatefulWidget {
  const QuranFloatingHero({
    super.key,
    this.playing = false,
  });

  final bool playing;

  @override
  State<QuranFloatingHero> createState() => _QuranFloatingHeroState();
}

class _QuranFloatingHeroState extends State<QuranFloatingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final dy = math.sin(_float.value * math.pi * 2) * 10;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.45),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: AppColors.primaryContainer, width: 4),
                boxShadow: AppShadows.clayLift,
              ),
              child: const Icon(
                Symbols.menu_book,
                size: 72,
                color: AppColors.primary,
                fill: 1,
              ),
            ),
            Positioned(
              right: 24,
              bottom: 8,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondaryContainer, width: 3),
                  boxShadow: AppShadows.soft,
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppAssets.logoBaby,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Symbols.child_care,
                      size: 40,
                      color: AppColors.primary,
                      fill: 1,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.playing)
              Positioned(
                top: 12,
                left: 28,
                child: _PulseDot(color: AppColors.secondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          width: 14 + _c.value * 6,
          height: 14 + _c.value * 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.35 + _c.value * 0.25),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
