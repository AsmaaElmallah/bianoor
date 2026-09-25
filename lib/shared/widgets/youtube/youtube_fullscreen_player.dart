import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'youtube_embed_player.dart';

Uri youtubeWatchUri({String? videoId, String? playlistId}) {
  final playlist = playlistId?.trim();
  if (playlist != null && playlist.isNotEmpty) {
    return Uri.parse('https://www.youtube.com/playlist?list=$playlist');
  }
  return Uri.parse('https://www.youtube.com/watch?v=${videoId?.trim() ?? ''}');
}

Future<void> launchYoutubeExternal({String? videoId, String? playlistId}) async {
  final uri = youtubeWatchUri(videoId: videoId, playlistId: playlistId);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> _enterLandscape() {
  return SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) => SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
}

Future<void> _restorePortrait() {
  return SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then(
    (_) => SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    ),
  );
}

/// يفتح المقطع بملء الشاشة. الفيديو المرفوع يُشغَّل داخل التطبيق؛ يوتيوب يُضمَّن أو يُفتح خارجياً.
Future<void> openYoutubeFullscreen(
  BuildContext context, {
  String? videoId,
  String? playlistId,
  String? videoUrl,
}) {
  final uploaded = videoUrl?.trim();
  if (uploaded != null && uploaded.isNotEmpty) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => UploadedVideoFullscreenScreen(videoUrl: uploaded),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
  if (!YoutubeEmbedPlayer.hasPlayableSource(videoId: videoId, playlistId: playlistId)) {
    return Future.value();
  }
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => YoutubeFullscreenPlayerScreen(
        videoId: videoId,
        playlistId: playlistId,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class UploadedVideoFullscreenScreen extends StatefulWidget {
  const UploadedVideoFullscreenScreen({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<UploadedVideoFullscreenScreen> createState() => _UploadedVideoFullscreenScreenState();
}

class _UploadedVideoFullscreenScreenState extends State<UploadedVideoFullscreenScreen> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _enterLandscape();
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      controller.play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تشغيل الفيديو');
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _restorePortrait();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.white))
                : !ready
                    ? const CircularProgressIndicator(color: Colors.white)
                    : GestureDetector(
                        onTap: () {
                          controller.value.isPlaying ? controller.pause() : controller.play();
                          setState(() {});
                        },
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio == 0
                              ? 16 / 9
                              : controller.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(controller),
                              if (!controller.value.isPlaying)
                                const Icon(Symbols.play_circle, color: Colors.white70, size: 72, fill: 1),
                            ],
                          ),
                        ),
                      ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Symbols.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class YoutubeFullscreenPlayerScreen extends StatefulWidget {
  const YoutubeFullscreenPlayerScreen({super.key, this.videoId, this.playlistId});

  final String? videoId;
  final String? playlistId;

  @override
  State<YoutubeFullscreenPlayerScreen> createState() => _YoutubeFullscreenPlayerScreenState();
}

class _YoutubeFullscreenPlayerScreenState extends State<YoutubeFullscreenPlayerScreen> {
  bool _fellBack = false;

  @override
  void initState() {
    super.initState();
    _enterLandscape();
  }

  @override
  void dispose() {
    _restorePortrait();
    super.dispose();
  }

  Future<void> _openExternal() =>
      launchYoutubeExternal(videoId: widget.videoId, playlistId: widget.playlistId);

  Future<void> _onEmbedError() async {
    if (_fellBack) return;
    _fellBack = true;
    await _openExternal();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: YoutubeEmbedPlayer(
              videoId: widget.videoId,
              playlistId: widget.playlistId,
              playing: true,
              borderRadius: BorderRadius.zero,
              onOpenExternal: _openExternal,
              onEmbedError: _onEmbedError,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Symbols.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'فتح في يوتيوب',
                  icon: const Icon(Symbols.open_in_new, color: Colors.white),
                  onPressed: _openExternal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
