import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingProgressDots extends StatelessWidget {
  const OnboardingProgressDots({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isActive ? 24 : 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isActive ? AppColors.progressActive : AppColors.progressInactive,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
