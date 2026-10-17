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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(ArenaIdentity.shortcutRadius),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ArenaIdentity.shortcutRadius),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 6, 3, 4),
            child: LayoutBuilder(
              builder: (context, c) {
                final well = (c.maxHeight * 0.46).clamp(22.0, 34.0);
                return Column(
                  children: [
                    Container(
                      width: well,
                      height: well,
                      decoration: BoxDecoration(
                        color: wellColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: well * 0.5,
                        weight: 500,
                        fill: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              height: 1.05,
                              fontSize: 9,
                            ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
