import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../features/library/domain/library_media_catalog.dart';
import 'youtube_thumbnail.dart';

/// صورة خلفية المقطع (من الإدارة أو YouTube) مع زر تشغيل؛ الضغط يفتح المشغّل بملء الشاشة.
class YoutubeCoverCard extends StatelessWidget {
  const YoutubeCoverCard({
    super.key,
    required this.item,
    required this.onPlay,
    this.borderRadius,
    this.accentColor,
    this.placeholderIcon = Symbols.play_circle,
    this.showPlayButton = true,
    this.wrapInAspectRatio = true,
  });

  final LibraryMediaItem item;
  final VoidCallback onPlay;
  final BorderRadius? borderRadius;
  final Color? accentColor;
  final IconData placeholderIcon;
  final bool showPlayButton;
  final bool wrapInAspectRatio;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: borderRadius ?? AppRadius.brLg,
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: onPlay,
          child: Stack(
            fit: StackFit.expand,
            children: [
              YoutubeThumbnail(
                key: ValueKey('cover_${item.id}_${item.coverUrl}'),
                videoId: item.videoId,
                imageUrl: item.coverUrl,
                icon: placeholderIcon,
                iconColor: accentColor,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x66000000)],
                  ),
                ),
              ),
              if (showPlayButton)
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.clayLift,
                    ),
                    child: Icon(
                      Symbols.play_arrow,
                      size: 44,
                      color: accentColor ?? AppColors.primary,
                      fill: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!wrapInAspectRatio) return card;
    return AspectRatio(aspectRatio: 16 / 9, child: card);
  }
}
