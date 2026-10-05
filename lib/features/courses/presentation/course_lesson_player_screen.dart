import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';

/// Lesson is counted as finished once the mother watches this share of it.
const _completeRatio = 0.9;

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

  void _seekBy(int seconds) {
    final controller = _controller;
    if (controller == null) return;
    final target = controller.value.position + Duration(seconds: seconds);
    controller.seekTo(target < Duration.zero ? Duration.zero : target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = _lesson;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final hasNext = _index < widget.lessons.length - 1;
    final hasPrev = _index > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.course.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: ready && controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : lesson.isYoutube
                      ? Center(
                          child: TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Symbols.play_circle, color: Colors.white),
                            label: const Text('تشغيل الدرس', style: TextStyle(color: Colors.white)),
                          ),
                        )
                      : !ready
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : GestureDetector(
                              onTap: () {
                                controller.value.isPlaying ? controller.pause() : controller.play();
                                setState(() {});
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(controller),
                                  ValueListenableBuilder<VideoPlayerValue>(
                                    valueListenable: controller,
                                    builder: (_, value, __) => value.isPlaying
                                        ? const SizedBox.shrink()
                                        : const Icon(Symbols.play_circle, color: Colors.white70, size: 72, fill: 1),
                                  ),
                                ],
                              ),
                            ),
            ),
          ),
          if (ready) ...[
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: AppColors.primaryContainer,
                backgroundColor: AppColors.outline,
              ),
            ),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (_, value, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'رجوع 10 ثواني',
                    icon: const Icon(Symbols.replay_10),
                    onPressed: () => _seekBy(-10),
                  ),
                  IconButton.filled(
                    iconSize: 32,
                    icon: Icon(value.isPlaying ? Symbols.pause : Symbols.play_arrow),
                    onPressed: () => value.isPlaying ? controller.pause() : controller.play(),
                  ),
                  IconButton(
                    tooltip: 'تقديم 10 ثواني',
                    icon: const Icon(Symbols.forward_10),
                    onPressed: () => _seekBy(10),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_format(value.position)} / ${_format(value.duration)}',
                    style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الدرس ${_index + 1} من ${widget.lessons.length}',
                  style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (_completed) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Symbols.check_circle, color: AppColors.tertiary, size: 18, fill: 1),
                      SizedBox(width: 4),
                      Text('خلّصتي الدرس ده'),
                    ],
                  ),
                ],
                if (lesson.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(lesson.description, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (hasPrev)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _goTo(_index - 1),
                          icon: const Icon(Symbols.arrow_forward),
                          label: const Text('الدرس السابق'),
                        ),
                      ),
                    if (hasPrev && hasNext) const SizedBox(width: 12),
                    if (hasNext)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _canOpen(_index + 1) ? () => _goTo(_index + 1) : null,
                          icon: const Icon(Symbols.arrow_back),
                          label: const Text('الدرس التالي'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canOpen(int index) {
    final hasAccess = ref.read(courseAccessProvider(widget.course.id)).valueOrNull ?? false;
    return hasAccess || widget.lessons[index].isPreview;
  }

  static String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}
