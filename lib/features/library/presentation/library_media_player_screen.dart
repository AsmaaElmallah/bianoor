import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../domain/library_media_catalog.dart';

/// تشغيل مقطع YouTube أو قائمة تهويدات عبر WebView.
class LibraryMediaPlayerScreen extends StatefulWidget {
  const LibraryMediaPlayerScreen({
    super.key,
    required this.title,
    this.videoId,
    this.playlistId,
  });

  final String title;
  final String? videoId;
  final String? playlistId;

  @override
  State<LibraryMediaPlayerScreen> createState() => _LibraryMediaPlayerScreenState();
}

class _LibraryMediaPlayerScreenState extends State<LibraryMediaPlayerScreen> {
  WebViewController? _webController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final playlist = widget.playlistId?.trim();
    final video = widget.videoId?.trim();

    if ((playlist == null || playlist.isEmpty) && (video == null || video.isEmpty)) {
      _error = 'لا يوجد رابط تشغيل';
      return;
    }

    final embedUrl = libraryYoutubeEmbedUrl(videoId: video, playlistId: playlist);
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surfaceContainer)
      ..loadRequest(Uri.parse(embedUrl));
  }

  Future<void> _openInYoutube() async {
    final playlist = widget.playlistId;
    final video = widget.videoId;
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: widget.title,
        onBack: () => context.pop(),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openInYoutube,
                      icon: const Icon(Symbols.open_in_new),
                      label: const Text('فتح في يوتيوب'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                ClipRRect(
                  borderRadius: AppRadius.brLg,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: WebViewWidget(controller: _webController!),
                  ),
                ),
                const SizedBox(height: 16),
                TactileClayCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يتطلب اتصالاً بالإنترنت. إن لم يظهر الفيديو، افتحي التطبيق في يوتيوب.',
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
