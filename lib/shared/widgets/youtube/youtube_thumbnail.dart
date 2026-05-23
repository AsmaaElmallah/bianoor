import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';

/// صورة مصغّرة YouTube بنسبة ثابتة وتدرّج fallback.
class YoutubeThumbnail extends StatelessWidget {
  const YoutubeThumbnail({
    super.key,
    this.videoId,
    this.fit = BoxFit.cover,
    this.icon = Symbols.play_circle,
    this.iconColor,
    this.backgroundColor,
  });

  final String? videoId;
  final BoxFit fit;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  static String? urlForVideoId(String? id) {
    final v = id?.trim();
    if (v == null || v.isEmpty) return null;
    return 'https://img.youtube.com/vi/$v/hqdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final url = urlForVideoId(videoId);
    final bg = backgroundColor ?? AppColors.surfaceContainer;
    final ic = iconColor ?? AppColors.primary;

    if (url == null) {
      return ColoredBox(
        color: bg,
        child: Center(child: Icon(icon, color: ic, size: 40, fill: 1)),
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: bg,
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => ColoredBox(
        color: bg,
        child: Center(child: Icon(icon, color: ic, size: 40, fill: 1)),
      ),
    );
  }
}
