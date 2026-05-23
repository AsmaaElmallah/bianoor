import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import 'youtube_embed_helper.dart';
import 'youtube_thumbnail.dart';

/// مشغّل YouTube موحّد — 16:9، iframe عبر HTML، معالجة خطأ 153.
class YoutubeEmbedPlayer extends StatefulWidget {
  const YoutubeEmbedPlayer({
    super.key,
    this.videoId,
    this.playlistId,
    this.playing = true,
    this.borderRadius,
    this.onOpenExternal,
    this.placeholderIcon = Symbols.play_circle,
    this.placeholderIconColor,
    this.wrapInAspectRatio = true,
  });

  final String? videoId;
  final String? playlistId;
  final bool playing;
  /// عند false يُستخدم داخل [AspectRatio] أب (مثل بطاقة النشاط).
  final bool wrapInAspectRatio;
  final BorderRadius? borderRadius;
  final Future<void> Function()? onOpenExternal;
  final IconData placeholderIcon;
  final Color? placeholderIconColor;

  static bool hasPlayableSource({String? videoId, String? playlistId}) {
    final v = videoId?.trim();
    final p = playlistId?.trim();
    return (v != null && v.isNotEmpty) || (p != null && p.isNotEmpty);
  }

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  WebViewController? _controller;
  bool _embedError = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.playing && YoutubeEmbedPlayer.hasPlayableSource(
          videoId: widget.videoId,
          playlistId: widget.playlistId,
        )) {
      _initPlayer();
    }
  }

  @override
  void didUpdateWidget(YoutubeEmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idsChanged = oldWidget.videoId != widget.videoId ||
        oldWidget.playlistId != widget.playlistId;
    final playChanged = oldWidget.playing != widget.playing;

    if (idsChanged) {
      _controller = null;
      _embedError = false;
    }

    if (widget.playing &&
        YoutubeEmbedPlayer.hasPlayableSource(
          videoId: widget.videoId,
          playlistId: widget.playlistId,
        )) {
      if (idsChanged || (playChanged && !oldWidget.playing)) {
        _initPlayer();
      }
    } else if (!widget.playing) {
      setState(() {
        _loading = false;
        _controller = null;
      });
    }
  }

  void _initPlayer() {
    setState(() {
      _loading = true;
      _embedError = false;
    });

    _controller = createYoutubeEmbedController(
      videoId: widget.videoId,
      playlistId: widget.playlistId,
      onWebResourceError: (_) {
        if (mounted) {
          setState(() {
            _embedError = true;
            _loading = false;
          });
        }
      },
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.brLg;
    final canPlay = YoutubeEmbedPlayer.hasPlayableSource(
      videoId: widget.videoId,
      playlistId: widget.playlistId,
    );

    final player = ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
              if (!canPlay)
                _Placeholder(
                  icon: widget.placeholderIcon,
                  iconColor: widget.placeholderIconColor,
                  message: 'لا يوجد رابط تشغيل',
                )
              else if (_embedError)
                _EmbedErrorOverlay(onOpenExternal: widget.onOpenExternal)
              else if (widget.playing && _controller != null) ...[
                WebViewWidget(controller: _controller!),
                if (_loading)
                  const ColoredBox(
                    color: Color(0xCC000000),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
              ] else
                YoutubeThumbnail(
                  videoId: widget.videoId,
                  icon: widget.placeholderIcon,
                  iconColor: widget.placeholderIconColor,
                ),
            ],
          ),
        ),
    );

    if (!widget.wrapInAspectRatio) return player;
    return AspectRatio(aspectRatio: 16 / 9, child: player);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    this.iconColor,
    this.message,
  });

  final IconData icon;
  final Color? iconColor;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: iconColor ?? AppColors.primary, fill: 1),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// حالة خطأ 153 / تعذّر التضمين.
class YoutubeEmbedErrorPanel extends StatelessWidget {
  const YoutubeEmbedErrorPanel({super.key, this.onOpenExternal});

  final Future<void> Function()? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return _EmbedErrorOverlay(onOpenExternal: onOpenExternal);
  }
}

class _EmbedErrorOverlay extends StatelessWidget {
  const _EmbedErrorOverlay({this.onOpenExternal});

  final Future<void> Function()? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.error_outline, color: Colors.white70, size: 40, fill: 1),
          const SizedBox(height: 10),
          Text(
            'تعذّر تشغيل الفيديو هنا',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'قد يكون المقطع مقيّداً داخل التطبيق',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          if (onOpenExternal != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onOpenExternal,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Symbols.open_in_new, size: 20),
              label: const Text('فتح في يوتيوب'),
            ),
          ],
        ],
      ),
    );
  }
}
