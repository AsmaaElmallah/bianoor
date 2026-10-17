import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/floating_widget.dart';

/// BeBo mascot hero — gentle floating animation + soft glow shadow below.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, this.babyName = 'طفلك'});

  final String babyName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 112,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 4,
              child: Container(
                width: 72,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 10,
              child: FloatingWidget(
                amplitude: 4,
                duration: const Duration(milliseconds: 4200),
                child: Image.asset(
                  AppAssets.mascotSpoonSitting,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 12,
              child: FloatingWidget(
                amplitude: 5,
                duration: const Duration(milliseconds: 3400),
                child: Image.asset(
                  AppAssets.mascotGirlStanding,
                  height: 62,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            FloatingWidget(
              amplitude: 6,
              duration: const Duration(milliseconds: 3800),
              child: Image.asset(
                AppAssets.mascotCapLying,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  AppAssets.logoBaby,
                  height: 92,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 92),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
