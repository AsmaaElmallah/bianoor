import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, this.babyName = 'طفلك'});

  final String babyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDim, AppColors.primary],
        ),
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.primaryGlow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -20,
            bottom: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك في رحلة $babyName اليوم',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                _Pill(
                  label: 'المستوى الحالي: المستوى 4',
                  filled: true,
                ),
                const SizedBox(height: 8),
                const _Pill(
                  label: 'التقدم الكلي: تقدم الطفل: 75%',
                  filled: false,
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(4, (i) {
                    final active = i == 1;
                    return Container(
                      width: active ? 8 : 6,
                      height: active ? 8 : 6,
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? AppColors.onPrimary
                            : AppColors.onPrimary.withValues(alpha: 0.35),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Image.asset(
                    AppAssets.logoBaby,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 120),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.brFull,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
