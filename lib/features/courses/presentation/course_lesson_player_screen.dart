import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/clay_kit.dart';
import '../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';

/// Lesson is counted as finished once the mother watches this share of it.
const _completeRatio = 0.9;

const _speeds = [1.0, 1.25, 1.5, 2.0];

class CourseLessonPlayerScreen extends ConsumerStatefulWidget {
  const CourseLessonPlayerScreen({
    super.key,
    required this.course,
    required this.lessons,
    required this.initialIndex,
  });

  final Course course;
  final List<CourseLesson> lessons;
  final int initialIndex;

  @override
  ConsumerState<CourseLessonPlayerScreen> createState() => _CourseLessonPlayerScreenState();
}

class _CourseLessonPlayerScreenState extends ConsumerState<CourseLessonPlayerScreen> {
  late int _index = widget.initialIndex;
  VideoPlayerController? _controller;
  String? _error;
  bool _completed = false;
  Timer? _saveTimer;
  int _tab = 0;
  double _speed = 1.0;
  bool _muted = false;

  late final CoursesRepository _repo;

  CourseLesson get _lesson => widget.lessons[_index];

  @override
  void initState() {
    super.initState();
    _repo = ref.read(coursesRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    final controller = _controller;
    if (controller != null) {
      _persist(controller, _lesson);
      controller.removeListener(_onTick);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final lesson = _lesson;
    setState(() {
      _error = null;
      _completed = false;
    });

    if (lesson.isYoutube) {
      await openYoutubeFullscreen(context, videoId: lesson.youtubeVideoId);
      await _repo.saveProgress(lesson: lesson, positionSeconds: 0, completed: true);
      if (mounted) setState(() => _completed = true);
      return;
    }

    final url = await _repo.signedVideoUrl(lesson);
    if (!mounted || lesson != _lesson) return;
    if (url == null) {
      setState(() => _error = 'الفيديو مش متاح دلوقتي — اتأكدي إن الدورة مفتوحة لك.');
      return;
    }

    final progress = await ref.read(courseProgressProvider(widget.course.id).future);
    final saved = progress[lesson.id];
    _completed = saved?.completed ?? false;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    try {
      await controller.initialize();
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر تشغيل الفيديو، اتأكدي من النت.');
      return;
    }
    if (!mounted || controller != _controller) return;

    final resumeAt = saved?.positionSeconds ?? 0;
    final total = controller.value.duration.inSeconds;
    if (resumeAt > 5 && (total == 0 || resumeAt < total - 5) && !(saved?.completed ?? false)) {
      await controller.seekTo(Duration(seconds: resumeAt));
    }
    await controller.setPlaybackSpeed(_speed);
    await controller.setVolume(_muted ? 0 : 1);
    controller.addListener(_onTick);
    await controller.play();
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final c = _controller;
      if (c != null && c.value.isPlaying) _persist(c, _lesson);
    });
    if (mounted) setState(() {});
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || _completed) return;
    final total = controller.value.duration.inMilliseconds;
    if (total <= 0) return;
    if (controller.value.position.inMilliseconds / total >= _completeRatio) {
      _completed = true;
      _persist(controller, _lesson);
      if (mounted) setState(() {});
    }
  }

  void _persist(VideoPlayerController controller, CourseLesson lesson) {
    if (!controller.value.isInitialized) return;
    _repo.saveProgress(
      lesson: lesson,
      positionSeconds: controller.value.position.inSeconds,
      completed: _completed,
    );
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= widget.lessons.length) return;
    final old = _controller;
    _saveTimer?.cancel();
    if (old != null) {
      _persist(old, _lesson);
      old.removeListener(_onTick);
      _controller = null;
      await old.dispose();
    }
    setState(() => _index = index);
    await _load();
  }

  Future<void> _markDone() async {
    setState(() => _completed = true);
    final controller = _controller;
    await _repo.saveProgress(
      lesson: _lesson,
      positionSeconds: controller != null && controller.value.isInitialized ? controller.value.position.inSeconds : 0,
      completed: true,
    );
    ref.invalidate(courseProgressProvider(widget.course.id));
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _controller?.setPlaybackSpeed(speed);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0 : 1);
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _FullscreenVideo(controller: controller)),
    );
  }

  bool _canOpen(int index) {
    final hasAccess = ref.read(courseAccessProvider(widget.course.id)).valueOrNull ?? false;
    return hasAccess || widget.lessons[index].isPreview;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final progress = ref.watch(courseProgressProvider(widget.course.id)).valueOrNull ?? const {};
    ref.watch(courseAccessProvider(widget.course.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ClayHeader(title: 'مشاهدة الدرس'),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _PlayerFrame(
            controller: _controller,
            error: _error,
            isYoutube: lesson.isYoutube,
            lessonNumber: _index + 1,
            speed: _speed,
            muted: _muted,
            onReplayYoutube: _load,
            onSpeed: _setSpeed,
            onToggleMute: _toggleMute,
            onFullscreen: _openFullscreen,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: ClayPill(
                        icon: Symbols.verified,
                        text: widget.course.title,
                        background: AppColors.primaryFixed,
                        foreground: AppColors.onPrimaryFixed,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الدرس ${_index + 1} من ${widget.lessons.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'الدرس ${_index + 1}: ${lesson.title}',
                  style: const TextStyle(fontSize: 22, height: 1.35, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                _LessonCard(
                  instructorName: widget.course.instructorName,
                  completed: _completed,
                  onMarkDone: _completed ? null : _markDone,
                ),
                const SizedBox(height: 20),
                ClaySegmented(
                  labels: ['قائمة الدروس (${widget.lessons.length})', 'عن الدرس'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                const SizedBox(height: 16),
                if (_tab == 1)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: clayDecoration(lift: 0.6),
                    child: Text(
                      lesson.description.isNotEmpty ? lesson.description : 'مفيش وصف للدرس ده.',
                      style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.onSurface),
                    ),
                  )
                else
                  for (var i = 0; i < widget.lessons.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: i == _index
                          ? _ActiveLessonCard(lesson: lesson, controller: _controller, completed: _completed)
                          : _PlaylistTile(
                              lesson: widget.lessons[i],
                              next: i == _index + 1,
                              unlocked: _canOpen(i),
                              completed: progress[widget.lessons[i].id]?.completed ?? false,
                              onTap: _canOpen(i) ? () => _goTo(i) : null,
                            ),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _format(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

class _PlayerFrame extends StatelessWidget {
  const _PlayerFrame({
    required this.controller,
    required this.error,
    required this.isYoutube,
    required this.lessonNumber,
    required this.speed,
    required this.muted,
    required this.onReplayYoutube,
    required this.onSpeed,
    required this.onToggleMute,
    required this.onFullscreen,
  });

  final VideoPlayerController? controller;
  final String? error;
  final bool isYoutube;
  final int lessonNumber;
  final double speed;
  final bool muted;
  final VoidCallback onReplayYoutube;
  final ValueChanged<double> onSpeed;
  final VoidCallback onToggleMute;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final ready = c != null && c.value.isInitialized;

    Widget content;
    if (error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        ),
      );
    } else if (isYoutube) {
      content = Center(
        child: _RoundOverlayButton(icon: Symbols.play_arrow, size: 64, primary: true, onTap: onReplayYoutube),
      );
    } else if (!ready) {
      content = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xE6493732), Color(0x4D493732), Color(0xB3493732)],
              ),
            ),
          ),
          _PlayerControls(
            controller: c,
            lessonNumber: lessonNumber,
            speed: speed,
            muted: muted,
            onSpeed: onSpeed,
            onToggleMute: onToggleMute,
            onFullscreen: onFullscreen,
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(kClayRadiusXl)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(aspectRatio: 16 / 10, child: content),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({
    required this.controller,
    required this.lessonNumber,
    required this.speed,
    required this.muted,
    required this.onSpeed,
    required this.onToggleMute,
    required this.onFullscreen,
  });

  final VideoPlayerController controller;
  final int lessonNumber;
  final double speed;
  final bool muted;
  final ValueChanged<double> onSpeed;
  final VoidCallback onToggleMute;
  final VoidCallback onFullscreen;

  void _seekBy(int seconds) {
    final target = controller.value.position + Duration(seconds: seconds);
    controller.seekTo(target < Duration.zero ? Duration.zero : target);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final total = value.duration.inMilliseconds;
        final played = total <= 0 ? 0.0 : (value.position.inMilliseconds / total).clamp(0.0, 1.0);
        final buffered = total <= 0 || value.buffered.isEmpty
            ? 0.0
            : (value.buffered.last.end.inMilliseconds / total).clamp(0.0, 1.0);
        return Stack(
          children: [
            PositionedDirectional(
              top: 16,
              start: 16,
              child: ClayPill(
                leading: const ClayPulseDot(color: AppColors.secondaryFixed, size: 8),
                text: 'الدرس $lessonNumber',
                background: AppColors.primary.withValues(alpha: 0.9),
                foreground: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundOverlayButton(icon: Symbols.replay_10, size: 44, onTap: () => _seekBy(-10)),
                  const SizedBox(width: 24),
                  _RoundOverlayButton(
                    icon: value.isPlaying ? Symbols.pause : Symbols.play_arrow,
                    size: 64,
                    primary: true,
                    onTap: () => value.isPlaying ? controller.pause() : controller.play(),
                  ),
                  const SizedBox(width: 24),
                  _RoundOverlayButton(icon: Symbols.forward_10, size: 44, onTap: () => _seekBy(10)),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          _format(value.position),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: _Scrubber(
                          played: played,
                          buffered: buffered,
                          onSeek: (ratio) => controller.seekTo(value.duration * ratio),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          _format(value.duration),
                          textAlign: TextAlign.end,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final s in _speeds)
                              GestureDetector(
                                onTap: () => onSpeed(s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: s == speed
                                      ? BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999))
                                      : null,
                                  child: Text(
                                    '${s == s.roundToDouble() ? s.toInt() : s}x',
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      color: s == speed ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontWeight: s == speed ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onToggleMute,
                        icon: Icon(muted ? Symbols.volume_off : Symbols.volume_up, color: Colors.white, size: 20),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onFullscreen,
                        icon: const Icon(Symbols.fullscreen, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.played, required this.buffered, required this.onSeek});

  final double played;
  final double buffered;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        double ratioAt(double dx) {
          final r = (dx / width).clamp(0.0, 1.0);
          return rtl ? 1 - r : r;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => onSeek(ratioAt(d.localPosition.dx)),
          onHorizontalDragUpdate: (d) => onSeek(ratioAt(d.localPosition.dx)),
          child: SizedBox(
            height: 22,
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: width * buffered,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: width * played,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixedDim,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: AppColors.primaryFixedDim.withValues(alpha: 0.8), blurRadius: 8)],
                  ),
                ),
                PositionedDirectional(
                  start: (width * played - 8).clamp(0.0, width - 16),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoundOverlayButton extends StatelessWidget {
  const _RoundOverlayButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AppColors.primary : Colors.white.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      elevation: primary ? 8 : 2,
      shadowColor: primary ? AppColors.primary.withValues(alpha: 0.6) : Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, color: Colors.white, size: primary ? 36 : 24, fill: 1),
        ),
      ),
    );
  }
}

class _FullscreenVideo extends StatefulWidget {
  const _FullscreenVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => c.value.isPlaying ? c.pause() : c.play(),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _RoundOverlayButton(
                icon: Symbols.fullscreen_exit,
                size: 44,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primaryFixedDim,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.instructorName,
    required this.completed,
    required this.onMarkDone,
  });

  final String instructorName;
  final bool completed;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: clayDecoration(lift: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (instructorName.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                  child: const Icon(Symbols.person, color: AppColors.primary, fill: 1, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      const Text(
                        'مدرّبة الدورة',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Material(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onMarkDone,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: completed ? AppColors.secondaryFixedDim : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Symbols.check,
                        size: 18,
                        color: completed ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        completed ? 'تم إكمال الدرس بنجاح! 🎉' : 'وضع علامة مكتمل على الدرس',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: completed ? AppColors.secondaryDim : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveLessonCard extends StatelessWidget {
  const _ActiveLessonCard({required this.lesson, required this.controller, required this.completed});

  final CourseLesson lesson;
  final VideoPlayerController? controller;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    Widget body(double ratio) {
      final percent = (ratio * 100).round();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryFixed.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(kClayRadiusLg),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Symbols.graphic_eq, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                            child: const Text(
                              'شغّال الآن',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (lesson.durationLabel != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              lesson.durationLabel!,
                              style: const TextStyle(color: AppColors.primaryDim, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: const TextStyle(color: AppColors.primaryDim, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.surfaceContainerHigh,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    final c = controller;
    if (c == null || !c.value.isInitialized) return body(completed ? 1 : 0);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: c,
      builder: (_, value, __) {
        final total = value.duration.inMilliseconds;
        return body(total <= 0 ? 0 : (value.position.inMilliseconds / total).clamp(0.0, 1.0));
      },
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.lesson,
    required this.next,
    required this.unlocked,
    required this.completed,
    required this.onTap,
  });

  final CourseLesson lesson;
  final bool next;
  final bool unlocked;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final duration = lesson.durationLabel;

    if (!unlocked) {
      return Opacity(
        opacity: 0.75,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(kClayRadiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.surfaceContainerHigh, shape: BoxShape.circle),
                child: const Icon(Symbols.lock, color: AppColors.onSurfaceVariant, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('مقفل', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                        if (duration != null) ...[
                          const SizedBox(width: 8),
                          Text(duration, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ],
                    ),
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'خاص بالمشتركات',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: clayDecoration(lift: 0.4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kClayRadiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: completed ? AppColors.tertiaryContainer : AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed ? Symbols.check : Symbols.play_arrow,
                    color: completed ? AppColors.tertiary : AppColors.primary,
                    size: 20,
                    fill: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (next || completed)
                            Text(
                              completed ? 'مكتمل' : 'الدرس التالي',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: completed ? AppColors.tertiary : AppColors.secondary,
                              ),
                            ),
                          if ((next || completed) && duration != null) const SizedBox(width: 8),
                          if (duration != null)
                            Text(duration, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
                const Icon(Symbols.chevron_right, color: AppColors.outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
