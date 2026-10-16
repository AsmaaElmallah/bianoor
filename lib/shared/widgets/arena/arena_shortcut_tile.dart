import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/arena_identity.dart';

/// Arena home shortcut: white tile + colored well + white line icon.
class ArenaShortcutTile extends StatelessWidget {
  const ArenaShortcutTile({
    super.key,
    required this.title,
    required this.icon,
    required this.wellColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color wellColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(ArenaIdentity.shortcutRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(ArenaIdentity.shortcutRadius),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ArenaIdentity.shortcutRadius),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            children: [
              Container(
                width: ArenaIdentity.shortcutWell,
                height: ArenaIdentity.shortcutWell,
                decoration: BoxDecoration(
                  color: wellColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 22, weight: 600, fill: 1),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      height: 1.15,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
