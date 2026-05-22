import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';

/// هيدر clay: رجوع دائري + عنوان العمر (tamareen-ansheta).
class MediaAgeTactileHeader extends StatelessWidget {
  const MediaAgeTactileHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onAction,
    this.actionIcon = Symbols.open_in_new,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onAction;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainerLow,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          boxShadow: AppShadows.clayLift,
        ),
        child: Row(
          children: [
            Material(
              color: AppColors.primaryContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onAction != null)
              IconButton(
                icon: Icon(actionIcon, color: AppColors.primary, fill: 1),
                onPressed: onAction,
              ),
          ],
        ),
      ),
    );
  }
}
