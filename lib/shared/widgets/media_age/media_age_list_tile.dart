import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../features/library/domain/library_media_catalog.dart';
import '../floating_decoration.dart';
import '../tactile/tactile_clay_card.dart';

/// بطاقة تمرين/نشاط في القائمة (تصميم tamareen-ansheta).
class MediaAgeListTile extends StatelessWidget {
  const MediaAgeListTile({
    super.key,
    required this.item,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
    required this.accentColor,
  });

  final LibraryMediaItem item;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = item.youtubeThumbnailUrl;

    return TactileClayCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: isActive
            ? BoxDecoration(
                border: Border(
                  right: BorderSide(color: accentColor, width: 8),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: AppRadius.brMd,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.85),
                    offset: const Offset(-1, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: thumb != null
                  ? Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Symbols.play_circle,
                        color: accentColor,
                        size: 36,
                      ),
                    )
                  : Icon(Symbols.playlist_play, color: accentColor, size: 36, fill: 1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive ? accentColor : AppColors.onSurface,
                    ),
                  ),
                  if (item.durationLabel != null || item.moodTag != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Symbols.schedule,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          [
                            if (item.durationLabel != null) item.durationLabel,
                            if (item.moodTag != null) item.moodTag,
                          ].join(' • '),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainer,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              alignment: Alignment.center,
              child: Icon(
                isCompleted ? Symbols.check : Symbols.play_circle,
                color: isCompleted ? AppColors.onPrimary : AppColors.outline,
                fill: isCompleted ? 1 : 0,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة العرض الرئيسية للمقطع الحالي.
class MediaAgeFeaturedCard extends StatelessWidget {
  const MediaAgeFeaturedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.videoArea,
    required this.playing,
    required this.onPlayPause,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final String? durationLabel;
  final Widget videoArea;
  final bool playing;
  final VoidCallback onPlayPause;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TactileClayCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: videoArea,
                ),
                if (!playing)
                  GestureDetector(
                    onTap: onPlayPause,
                    child: Container(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      alignment: Alignment.center,
                      child: FloatingDecoration(
                        amplitude: 8,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.clayLift,
                          ),
                          child: const Icon(
                            Symbols.play_arrow,
                            size: 44,
                            color: AppColors.onPrimary,
                            fill: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (durationLabel != null && durationLabel!.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: AppRadius.brFull,
                        boxShadow: AppShadows.soft,
                      ),
                      child: Text(
                        durationLabel!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
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
