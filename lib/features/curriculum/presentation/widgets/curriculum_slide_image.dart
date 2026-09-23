import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Displays a curriculum slide image from network URL or local asset path.
class CurriculumSlideImage extends StatelessWidget {
  const CurriculumSlideImage({
    super.key,
    this.imageUrls = const [],
    this.imageAssets = const [],
  });

  final List<String> imageUrls;
  final List<String> imageAssets;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isNotEmpty) {
      if (imageUrls.length == 1) {
        return _NetworkFit(url: imageUrls.first);
      }
      return Stack(
        fit: StackFit.expand,
        children: [for (final u in imageUrls) _NetworkFit(url: u)],
      );
    }

    if (imageAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: AppColors.outline.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(
              'لا توجد شريحة منشورة من الإدارة بعد',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (imageAssets.length == 1) {
      return _AssetFit(path: imageAssets.first);
    }
    return Stack(
      fit: StackFit.expand,
      children: [for (final p in imageAssets) _AssetFit(path: p)],
    );
  }
}

class _NetworkFit extends StatelessWidget {
  const _NetworkFit({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.outline),
      ),
    );
  }
}

class _AssetFit extends StatelessWidget {
  const _AssetFit({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
