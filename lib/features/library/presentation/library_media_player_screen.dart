import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../../shared/widgets/youtube/youtube_embed_player.dart';

/// تشغيل مقطع YouTube أو قائمة تهويدات.
class LibraryMediaPlayerScreen extends StatelessWidget {
  const LibraryMediaPlayerScreen({
    super.key,
    required this.title,
    this.videoId,
    this.playlistId,
  });

  final String title;
  final String? videoId;
  final String? playlistId;

  Future<void> _openInYoutube() async {
    final playlist = playlistId?.trim();
    final video = videoId?.trim();
    final uri = playlist != null && playlist.isNotEmpty
        ? Uri.parse('https://www.youtube.com/playlist?list=$playlist')
        : Uri.parse('https://www.youtube.com/watch?v=$video');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPlay = YoutubeEmbedPlayer.hasPlayableSource(
      videoId: videoId,
      playlistId: playlistId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: title,
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          YoutubeEmbedPlayer(
            key: ValueKey('lib_${videoId}_$playlistId'),
            videoId: videoId,
            playlistId: playlistId,
            playing: canPlay,
            onOpenExternal: _openInYoutube,
          ),
          const SizedBox(height: 16),
          TactileClayCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يتطلب اتصالاً بالإنترنت. إن لم يظهر الفيديو، افتحي المقطع في تطبيق يوتيوب.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openInYoutube,
                  icon: const Icon(Symbols.open_in_new),
                  label: const Text('فتح في يوتيوب'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
