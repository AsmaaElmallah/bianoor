import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/pebble_progress.dart';
import '../data/video_rotation_service.dart';

class VideoIntroScreen extends ConsumerStatefulWidget {
  const VideoIntroScreen({super.key});

  @override
  ConsumerState<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends ConsumerState<VideoIntroScreen> {
  VideoPlayerController? _videoController;
  List<String> _videos = const [];
  bool _initFailed = false;
  bool _isLoading = true;
  int _currentIndex = 0;
  int _totalVideos = 0;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final service = ref.read(videoRotationServiceProvider);
    final videos = await service.getAvailableVideos();
    if (videos.isEmpty) {
      if (!mounted) return;
      setState(() {
        _initFailed = true;
        _isLoading = false;
        _videos = const [];
        _totalVideos = 0;
      });
      return;
    }
    final startIndex = await service.peekCurrentIndex();
    final safeIndex = startIndex % videos.length;
    if (!mounted) return;
    setState(() {
      _videos = videos;
      _totalVideos = videos.length;
      _currentIndex = safeIndex;
    });
    await _loadVideoAt(safeIndex);
  }

  Future<void> _loadVideoAt(int index) async {
    if (_videos.isEmpty) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _initFailed = false;
      });
    }
    await _disposeVideoController();
    final asset = _videos[index];
    try {
      await rootBundle.load(asset);
    } catch (_) {
      if (mounted) {
        setState(() {
          _initFailed = true;
          _isLoading = false;
        });
      }
      return;
    }

    final controller = VideoPlayerController.asset(asset);
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _initFailed = true;
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _currentIndex = index;
      _videoController = controller;
      _isLoading = false;
      _initFailed = false;
    });
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  Future<void> _disposeVideoController() async {
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _togglePlayback() async {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
  }

  Future<void> _goToLogin() async {
    final service = ref.read(videoRotationServiceProvider);
    await service.saveNextStartIndex(_currentIndex + 1);
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _next() async {
    if (_isLoading || _totalVideos == 0) return;
    final isLast = _currentIndex >= _totalVideos - 1;
    if (isLast) {
      await _goToLogin();
      return;
    }
    await _loadVideoAt(_currentIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 14,
              right: 26,
              child: Icon(
                Symbols.child_care,
                size: 72,
                color: AppColors.primary.withValues(alpha: 0.18),
                fill: 1,
              ),
            ),
            Positioned(
              bottom: -12,
              left: 8,
              child: Transform.rotate(
                angle: -0.22,
                child: Icon(
                  Symbols.extension,
                  size: 90,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  fill: 1,
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 12,
                                left: 8,
                                child: Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondaryContainer.withValues(alpha: 0.24),
                                        blurRadius: 56,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 420),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 5,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainer,
                                        borderRadius: AppRadius.brXl,
                                        border: Border.all(
                                          color: AppColors.surfaceContainerLowest,
                                          width: 12,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x0F31332F),
                                            blurRadius: 64,
                                            spreadRadius: -12,
                                            offset: Offset(0, 32),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _buildVideoArea(),
                                    ),
                                  ),
                                ),
                              ),
                              PositionedDirectional(
                                bottom: -44,
                                end: -8,
                                child: SizedBox(
                                  width: 176,
                                  height: 176,
                                  child: Image.asset(
                                    AppAssets.logoBaby,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Symbols.child_care,
                                      color: AppColors.primary,
                                      size: 92,
                                      fill: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 68),
                        Text(
                          'تعلم باللعب',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'دروس ومناهج مصممة خصيصاً لتنمية مهارات طفلك بأسلوب ممتع',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const PebbleProgress(
                          totalSteps: 3,
                          currentStep: 0,
                          dotSize: 8,
                          activeWidth: 8,
                          spacing: 8,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 18, 32, 26),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppShadows.editorial,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: _isLoading ? null : _next,
                              child: Center(
                                child: Text(
                                  _currentIndex >= _totalVideos - 1 ? 'ابدأ الآن' : 'التالي',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isLoading ? null : _goToLogin,
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          foregroundColor: AppColors.onSurfaceVariant,
                        ),
                        child: Text(
                          'تخطي',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_initFailed || _videos.isEmpty) {
      return _VideoPlaceholder(currentIndex: _currentIndex, total: _totalVideos);
    }
    if (_isLoading || _videoController == null || !_videoController!.value.isInitialized) {
      return const ColoredBox(
        color: AppColors.surfaceContainerHigh,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
    }
    final controller = _videoController!;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlayback,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  if (controller.value.isPlaying) {
                    return const SizedBox.expand();
                  }
                  return Center(
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      elevation: 6,
                      shadowColor: Colors.black38,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _togglePlayback,
                        child: const SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(
                            Symbols.play_arrow,
                            size: 40,
                            color: AppColors.primary,
                            fill: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.currentIndex, required this.total});
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.surfaceContainerHigh,
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Symbols.play_arrow, size: 36, color: AppColors.primary, fill: 1),
          ),
          const SizedBox(height: 12),
          Text(
            'فيديو ${currentIndex + 1} / $total',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
