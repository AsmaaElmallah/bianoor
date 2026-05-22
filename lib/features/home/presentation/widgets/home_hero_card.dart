import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../shared/widgets/floating_widget.dart';

/// BeBo mascot hero — gentle floating animation + soft glow shadow below.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, this.babyName = 'طفلك'});

  final String babyName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft glow ellipse below mascot
            Positioned(
              bottom: 8,
              child: Container(
                width: 110,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF00AFAA).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),

            // Floating mascot
            FloatingWidget(
              amplitude: 9,
              duration: const Duration(milliseconds: 3800),
              child: Image.asset(
                AppAssets.mascotCapLying,
                height: 170,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  AppAssets.logoBaby,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 160),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
