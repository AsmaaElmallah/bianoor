import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../domain/library_hub_theme.dart';
import '../../domain/library_media_catalog.dart';

class LibraryTrackTile extends StatelessWidget {
  const LibraryTrackTile({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.listStyle,
    this.showFavorite = false,
  });

  final LibraryMediaItem item;
  final bool isActive;
  final VoidCallback onTap;
  final LibraryHubListStyle listStyle;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = item.youtubeThumbnailUrl;

    if (listStyle == LibraryHubListStyle.queue) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryContainer.withValues(alpha: 0.25)
                  : Colors.transparent,
              borderRadius: AppRadius.brMd,
            ),
            child: Row(
              children: [
                _Thumbnail(url: thumbUrl, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      if (item.durationLabel != null)
                        Text(
                          '${item.durationLabel}${item.moodTag != null ? ' • ${item.moodTag}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.more_vert,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TactileClayCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: isActive
          ? AppColors.surfaceBright
          : AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Thumbnail(url: thumbUrl, size: 64),
                if (isActive)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      borderRadius: AppRadius.brMd,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Symbols.play_circle,
                      color: Colors.white,
                      fill: 1,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.durationLabel != null)
                  Text(
                    '${item.durationLabel}${item.moodTag != null ? ' • ${item.moodTag}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (showFavorite)
            IconButton(
              icon: const Icon(Symbols.favorite, color: AppColors.outline),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brMd,
      child: Container(
        width: size,
        height: size,
        color: AppColors.primaryFixed,
        child: url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Symbols.music_note,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Symbols.playlist_play, color: AppColors.primary, fill: 1),
      ),
    );
  }
}
