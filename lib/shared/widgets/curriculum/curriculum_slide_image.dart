import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_colors.dart';

/// صورة شريحة — asset محلي أو رابط شبكة (Supabase Storage).
class CurriculumSlideImage extends StatelessWidget {
  const CurriculumSlideImage({
    super.key,
    required this.sources,
    this.fit = BoxFit.contain,
  });

  final List<String> sources;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, size: 56, color: AppColors.outline),
            const SizedBox(height: 8),
            Text(
              'تعذر تحميل الشريحة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (sources.length == 1) {
      return _SlideImageSource(path: sources.first, fit: fit);
    }

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        for (final path in sources) _SlideImageSource(path: path, fit: fit),
      ],
    );
  }
}

class _SlideImageSource extends StatelessWidget {
  const _SlideImageSource({required this.path, required this.fit});

  final String path;
  final BoxFit fit;

  bool get _isNetwork => path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return Image.network(
        path,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => _error(context),
      );
    }

    return Image.asset(
      path,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _error(context),
    );
  }

  Widget _error(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'ملف غير موجود',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
        ),
      ),
    );
  }
}

/// تشغيل صوت الشريحة — شبكة أولاً ثم asset.
Future<bool> playCurriculumSlideAudio(AudioPlayer player, String? playableAudio) async {
  if (playableAudio == null) return false;

  final isNetwork =
      playableAudio.startsWith('http://') || playableAudio.startsWith('https://');

  try {
    if (isNetwork) {
      await player.setUrl(playableAudio);
    } else {
      await player.setAsset(playableAudio);
    }
    await player.play();
    return true;
  } catch (_) {
    return false;
  }
}
