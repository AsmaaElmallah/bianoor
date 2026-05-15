import 'package:flutter/material.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../shared/widgets/app_logo_avatar.dart';

/// Header with mascot + بيانور (_2q / _3q tactile style).
class QuranTactileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QuranTactileAppBar({
    super.key,
    this.title = 'بيانور',
    this.showStars = false,
    this.starsCount = 0,
    this.onBack,
  });

  final String title;
  final bool showStars;
  final int starsCount;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.clayLift,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onPressed: onBack,
                )
              else
                const SizedBox(width: 8),
              const AppLogoAvatar(
                size: 44,
                imageAsset: AppAssets.logoBaby,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (showStars)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.05),
                        offset: const Offset(1, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$starsCount',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryDim,
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
