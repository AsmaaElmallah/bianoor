import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/clay_kit.dart';
import '../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../../library/data/library_sections_repository.dart';
import '../../live/data/live_repository.dart';
import '../../live/domain/live_session.dart';
import '../../live/presentation/live_sessions_screen.dart';
import '../../payments/data/payment_settings_repository.dart';
import '../../payments/domain/payment_item.dart';
import '../../payments/presentation/payment_options_sheet.dart';
import '../data/course_purchase_service.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';
import 'course_lesson_player_screen.dart';
import 'widgets/course_access_badge.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) => CoursesHubScreen(initialCourseId: course.id);
}

/// The one «الدورات» page: intro video, then pick a course, then its lessons.
class CoursesHubScreen extends ConsumerStatefulWidget {
  const CoursesHubScreen({super.key, this.initialCourseId});

  final String? initialCourseId;

  @override
  ConsumerState<CoursesHubScreen> createState() => _CoursesHubScreenState();
}

class _CoursesHubScreenState extends ConsumerState<CoursesHubScreen> {
  String? _selectedId;

  Future<void> _refresh() async {
    ref.invalidate(coursesHubProvider);
    ref.invalidate(coursesProvider);
    ref.invalidate(liveSessionsProvider);
    final id = _selectedId;
    if (id != null) {
      ref.invalidate(courseAccessProvider(id));
      ref.invalidate(courseProgressProvider(id));
      ref.invalidate(courseLessonsProvider(id));
      ref.invalidate(courseResourcesProvider(id));
    }
    await ref.read(coursesProvider.future);
  }

  Future<void> _openLesson(Course course, List<CourseLesson> lessons, int index) async {
    final lesson = lessons[index];
    if (lesson.isYoutube) {
      await openYoutubeFullscreen(context, videoId: lesson.youtubeVideoId);
      await ref.read(coursesRepositoryProvider).saveProgress(
            lesson: lesson,
            positionSeconds: 0,
            completed: true,
          );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CourseLessonPlayerScreen(
            course: course,
            lessons: lessons,
            initialIndex: index,
          ),
        ),
      );
    }
    ref.invalidate(courseProgressProvider(course.id));
  }

  Future<void> _playIntro(CoursesHub hub) async {
    if (!hub.hasIntro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فيديو التعريف هينزل قريب 🌸')),
      );
      return;
    }
    await openYoutubeFullscreen(
      context,
      videoId: hub.introYoutubeId,
      videoUrl: hub.introVideoUrl,
    );
  }

  Future<void> _contactForCourse(Course course) async {
    final number = await ref.read(libraryWhatsappNumberProvider.future);
    if (!mounted) return;
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم التواصل غير متاح حالياً، حاولي لاحقاً.')),
      );
      return;
    }
    final uri = Uri.https('wa.me', '/$number', {
      'text': 'مرحباً، أرغب في الاشتراك في دورة: ${course.title}',
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hub = ref.watch(coursesHubProvider).valueOrNull ?? const CoursesHub();
    final courses = ref.watch(coursesProvider).valueOrNull ?? const <Course>[];
    var selectedId = _selectedId ?? widget.initialCourseId;
    if (courses.isNotEmpty && (selectedId == null || !courses.any((c) => c.id == selectedId))) {
      selectedId = courses.first.id;
    }
    final selectedIndex = courses.indexWhere((c) => c.id == selectedId);
    final course = selectedIndex < 0 ? null : courses[selectedIndex];
    final courseId = course?.id;
    final asyncLessons = courseId == null ? null : ref.watch(courseLessonsProvider(courseId));
    final asyncAccess = courseId == null ? null : ref.watch(courseAccessProvider(courseId));
    final hasAccess = asyncAccess?.valueOrNull ?? false;
    final progress = courseId == null
        ? const <String, LessonProgress>{}
        : ref.watch(courseProgressProvider(courseId)).valueOrNull ?? const {};
    final resources = courseId == null
        ? const <CourseResource>[]
        : ref.watch(courseResourcesProvider(courseId)).valueOrNull ?? const <CourseResource>[];
    final lessons = asyncLessons?.valueOrNull ?? const <CourseLesson>[];
    final lessonCount = lessons.isEmpty ? (course?.lessonCount ?? 0) : lessons.length;
    final pageTitle = hub.title.isNotEmpty ? hub.title : 'الدورات';
    final pageSubtitle = hub.subtitle.isNotEmpty ? hub.subtitle : (course?.subtitle ?? '');
    final pageDescription = hub.description.isNotEmpty ? hub.description : (course?.description ?? '');
    final category = hub.categoryLabel.isNotEmpty ? hub.categoryLabel : (course?.categoryLabel ?? '');
    final instructorName = hub.instructorName.isNotEmpty ? hub.instructorName : (course?.instructorName ?? '');
    final instructorTitle = hub.instructorTitle.isNotEmpty ? hub.instructorTitle : (course?.instructorTitle ?? '');
    final instructorAvatar = hub.instructorAvatarUrl ?? course?.instructorAvatarUrl;
    final saved = course != null && ref.watch(prefsServiceProvider).isCourseSaved(course.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClayHeader(
        title: 'الدورات',
        saved: course == null ? null : saved,
        onToggleSave: course == null
            ? null
            : () async {
                final next = !saved;
                await ref.read(prefsServiceProvider).setCourseSaved(course.id, next);
                if (mounted) setState(() {});
              },
      ),
      bottomNavigationBar: course != null && asyncAccess?.valueOrNull == false
          ? _PurchaseBar(
              course: course,
              onSubscribe: () => context.push(AppRoutes.subscription),
              onContact: () => _contactForCourse(course),
            )
          : null,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLowest,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _PromoCard(
              coverUrl: hub.introCoverUrl ?? course?.coverUrl,
              label: 'تعرّفي على الدورات',
              onPlay: () => _playIntro(hub),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (category.isNotEmpty)
                  ClayPill(
                    icon: Symbols.child_care,
                    text: category,
                    background: AppColors.primaryFixed,
                    foreground: AppColors.onPrimaryFixedVariant,
                    iconColor: AppColors.primary,
                  ),
                if (course != null)
                  ClayPill(
                    icon: Symbols.play_circle,
                    text: '$lessonCount درس',
                    background: AppColors.secondaryFixed,
                    foreground: AppColors.onSecondaryFixed,
                    iconColor: AppColors.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              pageTitle,
              style: const TextStyle(
                fontSize: 28,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            if (pageSubtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                pageSubtitle,
                style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.onSurfaceVariant),
              ),
            ],
            if (pageDescription.isNotEmpty && pageDescription != pageSubtitle) ...[
              const SizedBox(height: 8),
              Text(
                pageDescription,
                style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.onSurfaceVariant),
              ),
            ],
            if (instructorName.isNotEmpty || (hub.facebookUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _InstructorCard(
                name: instructorName.isNotEmpty ? instructorName : 'بيانور',
                title: instructorTitle,
                avatarUrl: instructorAvatar,
                facebookUrl: hub.facebookUrl,
              ),
            ],
            if (course != null) _CourseLiveSection(courseId: course.id),
            const SizedBox(height: 24),
            if (courses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('الدورات هتنزل قريب، تابعينا 🌸', textAlign: TextAlign.center),
              )
            else ...[
              _CourseStrip(
                courses: courses,
                selectedId: selectedId,
                onSelected: (id) => setState(() => _selectedId = id),
              ),
              const SizedBox(height: 16),
              if (course == null)
                const SizedBox.shrink()
              else if (asyncLessons == null)
                const SizedBox.shrink()
              else
                asyncLessons.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('تعذّر تحميل الدروس، اسحبي لتحت للمحاولة تاني.', textAlign: TextAlign.center),
                  ),
                  data: (loaded) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (loaded.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('الدروس هتنزل قريب 🌸', textAlign: TextAlign.center),
                        )
                      else
                        _Curriculum(
                          lessons: loaded,
                          hasAccess: hasAccess,
                          progress: progress,
                          onOpen: (index) => _openLesson(course, loaded, index),
                        ),
                      if (resources.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _FilesTab(resources: resources, hasAccess: hasAccess),
                      ],
                    ],
                  ),
                ),
            ],
          ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseStrip extends StatelessWidget {
  const _CourseStrip({required this.courses, required this.selectedId, required this.onSelected});

  final List<Course> courses;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  Widget _chip(Course course, {bool expanded = false}) {
    final selected = course.id == selectedId;
    final chip = GestureDetector(
      onTap: () => onSelected(course.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: selected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : null,
        child: Text(
          course.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
    return expanded ? Expanded(child: chip) : Padding(padding: const EdgeInsetsDirectional.only(end: 6), child: chip);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: courses.length <= 3
          ? Row(children: [for (final course in courses) _chip(course, expanded: true)])
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [for (final course in courses) _chip(course)]),
            ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.coverUrl,
    required this.label,
    required this.onPlay,
  });

  final String? coverUrl;
  final String label;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: clayDecoration(lift: 1.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kClayRadiusLg - 6),
        child: SizedBox(
          height: 224,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPlay,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CourseCover(url: coverUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC493732), Color(0x33493732), Color(0x00493732)],
                      ),
                    ),
                  ),
                  if (onPlay != null) ...[
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: ClayPill(
                        icon: Symbols.visibility,
                        text: label,
                        background: AppColors.primary.withValues(alpha: 0.9),
                        foreground: Colors.white,
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixedDim,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryFixedDim.withValues(alpha: 0.6),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Symbols.play_arrow, size: 36, color: AppColors.onPrimaryContainer, fill: 1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({
    required this.name,
    required this.title,
    this.avatarUrl,
    this.facebookUrl,
  });

  final String name;
  final String title;
  final String? avatarUrl;
  final String? facebookUrl;

  Uri? _facebookUri() {
    final raw = facebookUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    return Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
  }

  Future<void> _openFacebook(BuildContext context) async {
    final uri = _facebookUri();
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حطي لينك الفيسبوك من لوحة التحكم أولاً')),
      );
      return;
    }
    const modes = [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ];
    for (final mode in modes) {
      try {
        if (await launchUrl(uri, mode: mode)) return;
      } catch (_) {}
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر فتح صفحة الفيسبوك')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: clayDecoration(color: AppColors.surfaceContainerLow, lift: 0.6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Symbols.person, color: AppColors.primary, fill: 1, size: 28),
                  )
                : const Icon(Symbols.person, color: AppColors.primary, fill: 1, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Symbols.verified, size: 18, color: AppColors.primary, fill: 1),
                  ],
                ),
                Text(
                  title.isNotEmpty ? title : 'مدرّبة الدورة',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.25),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _openFacebook(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.add, size: 16, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'متابعة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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

LiveSession? _pickCourseLive(List<LiveSession> all, String courseId) {
  final ofCourse = all.where((s) => s.courseId == courseId).toList();
  if (ofCourse.isEmpty) return null;
  for (final s in ofCourse) {
    if (s.status == LiveStatus.live) return s;
  }
  final scheduled = ofCourse.where((s) => s.status == LiveStatus.scheduled).toList()
    ..sort((a, b) {
      final at = a.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
  final now = DateTime.now();
  for (final s in scheduled) {
    if (s.scheduledAt == null || !s.scheduledAt!.isBefore(now)) return s;
  }
  if (scheduled.isNotEmpty) return scheduled.last;
  ofCourse.sort((a, b) => (b.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0))
      .compareTo(a.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
  return ofCourse.first;
}

/// The course's own live session (live now, next scheduled, or the latest ended).
class _CourseLiveSection extends ConsumerStatefulWidget {
  const _CourseLiveSection({required this.courseId});

  final String courseId;

  @override
  ConsumerState<_CourseLiveSection> createState() => _CourseLiveSectionState();
}

class _CourseLiveSectionState extends ConsumerState<_CourseLiveSection> {
  late final Timer _clock = Timer.periodic(const Duration(seconds: 1), (_) {
    if (mounted) setState(() {});
  });

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _pickCourseLive(
      ref.watch(liveSessionsProvider).valueOrNull ?? const <LiveSession>[],
      widget.courseId,
    );
    if (session == null) return const SizedBox.shrink();

    final isLive = session.status == LiveStatus.live;
    final ended = session.showAsEnded;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: clayDecoration(
          lift: 0.8,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              kClayAccentLight,
              Colors.white,
              AppColors.surfaceContainerLow,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 8,
              children: [
                ClayPill(
                  leading: isLive ? const ClayPulseDot() : null,
                  text: isLive
                      ? 'مباشر الآن'
                      : ended
                          ? 'انتهى'
                          : 'جلسة بث تفاعلية مباشرة',
                  background: ended ? AppColors.surfaceContainerHigh : AppColors.errorContainer,
                  foreground: ended ? AppColors.onSurfaceVariant : AppColors.onErrorContainer,
                ),
                if (!isLive && !ended) _CountdownPill(at: session.scheduledAt),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              session.title,
              style: const TextStyle(fontSize: 20, height: 1.35, fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (session.scheduleLabel != null)
                  _MetaLine(icon: Symbols.calendar_today, color: AppColors.primary, text: session.scheduleLabel!),
                if (session.instructorName.isNotEmpty)
                  _MetaLine(icon: Symbols.person, color: kClayAccent, text: session.instructorName),
              ],
            ),
            const SizedBox(height: 16),
            ClayChunkyButton(
              label: isLive
                  ? 'انضمي للقاعة التفاعلية المباشرة'
                  : ended
                      ? 'انتهى'
                      : 'اللايف هيبدأ في الميعاد',
              color: ended ? AppColors.outline : kClayAccent,
              edgeColor: ended ? AppColors.outlineVariant : AppColors.primaryDim,
              leadingIcon: isLive ? Symbols.mic : (ended ? Symbols.check_circle : Symbols.timer),
              trailingIcon: isLive ? Symbols.headphones : null,
              fontSize: 15,
              onPressed: () => openLiveSession(context, ref, session),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({this.at});

  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final left = at?.difference(DateTime.now());
    if (left == null || left.inSeconds <= 0) {
      return const ClayPill(
        icon: Symbols.check_circle,
        text: 'انتهى',
        background: AppColors.surfaceContainerHigh,
        foreground: AppColors.onSurface,
        iconColor: AppColors.onSurfaceVariant,
      );
    }
    String two(int n) => n.toString().padLeft(2, '0');
    final days = left.inDays;
    final clock =
        '${two(left.inHours.remainder(24))}:${two(left.inMinutes.remainder(60))}:${two(left.inSeconds.remainder(60))}';
    return ClayPill(
      icon: Symbols.timer,
      text: days > 0 ? 'متبقي $daysي $clock' : 'متبقي $clock',
      background: AppColors.secondaryContainer,
      foreground: AppColors.onSurface,
      iconColor: kClayAccent,
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Curriculum extends StatelessWidget {
  const _Curriculum({
    required this.lessons,
    required this.hasAccess,
    required this.progress,
    required this.onOpen,
  });

  final List<CourseLesson> lessons;
  final bool hasAccess;
  final Map<String, LessonProgress> progress;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    Widget tile(int i, {required bool firstInGroup}) {
      final lesson = lessons[i];
      final unlocked = hasAccess || lesson.isPreview;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _LessonTile(
          lesson: lesson,
          unlocked: unlocked,
          highlighted: firstInGroup && unlocked,
          showPreviewTag: lesson.isPreview && !hasAccess,
          completed: progress[lesson.id]?.completed ?? false,
          onTap: unlocked
              ? () => onOpen(i)
              : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الدرس ده مقفول — افتحي الدورة الأول.')),
                  ),
        ),
      );
    }

    if (lessons.any((l) => l.unitTitle.isNotEmpty)) {
      final units = <String, List<int>>{};
      for (var i = 0; i < lessons.length; i++) {
        units.putIfAbsent(lessons[i].unitTitle, () => []).add(i);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final unit in units.entries) ...[
            _UnitHeader(
              title: unit.key.isNotEmpty ? unit.key : 'دروس الدورة',
              hasAccess: hasAccess,
              allFree: unit.value.every((i) => lessons[i].isPreview),
            ),
            const SizedBox(height: 12),
            for (final i in unit.value)
              tile(i, firstInGroup: i == unit.value.firstWhere((j) => hasAccess || lessons[j].isPreview, orElse: () => -1)),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    if (hasAccess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClaySectionTitle(
            title: 'دروس الدورة',
            trailing: const ClayPill(
              text: 'مفتوحة لكِ',
              fontSize: 12,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lessons.length; i++) tile(i, firstInGroup: i == 0),
        ],
      );
    }

    final free = [for (var i = 0; i < lessons.length; i++) if (lessons[i].isPreview) i];
    final locked = [for (var i = 0; i < lessons.length; i++) if (!lessons[i].isPreview) i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (free.isNotEmpty) ...[
          const ClaySectionTitle(
            title: 'الدروس المجانية',
            trailing: ClayPill(
              text: 'متاحة مجاناً',
              fontSize: 12,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            ),
          ),
          const SizedBox(height: 12),
          for (final i in free) tile(i, firstInGroup: i == free.first),
          const SizedBox(height: 8),
        ],
        if (locked.isNotEmpty) ...[
          const ClaySectionTitle(
            title: 'باقي دروس الدورة',
            barColor: kClayAccent,
            trailing: ClayPill(
              icon: Symbols.lock,
              text: 'يتطلب اشتراك',
              fontSize: 12,
              background: AppColors.errorContainer,
              foreground: AppColors.onErrorContainer,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            ),
          ),
          const SizedBox(height: 12),
          for (final i in locked) tile(i, firstInGroup: false),
        ],
      ],
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.title, required this.hasAccess, required this.allFree});

  final String title;
  final bool hasAccess;
  final bool allFree;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 3);
    if (hasAccess || allFree) {
      return ClaySectionTitle(
        title: title,
        trailing: ClayPill(text: hasAccess ? 'مفتوحة لكِ' : 'متاحة مجاناً', fontSize: 12, padding: padding),
      );
    }
    return ClaySectionTitle(
      title: title,
      barColor: kClayAccent,
      trailing: const ClayPill(
        icon: Symbols.lock,
        text: 'يتطلب اشتراك',
        fontSize: 12,
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        padding: padding,
      ),
    );
  }
}

class _FilesTab extends ConsumerWidget {
  const _FilesTab({required this.resources, required this.hasAccess});

  final List<CourseResource> resources;
  final bool hasAccess;

  Future<void> _open(BuildContext context, WidgetRef ref, CourseResource resource) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!hasAccess && !resource.isPreview) {
      messenger.showSnackBar(const SnackBar(content: Text('الملف ده للمشتركات — افتحي الدورة الأول.')));
      return;
    }
    final url = await ref.read(coursesRepositoryProvider).signedResourceUrl(resource);
    if (url == null) {
      messenger.showSnackBar(const SnackBar(content: Text('تعذّر فتح الملف، حاولي تاني.')));
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (resources.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('ملفات الدورة هتنزل قريب 🌸', textAlign: TextAlign.center),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in resources)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FileTile(
              resource: r,
              unlocked: hasAccess || r.isPreview,
              onTap: () => _open(context, ref, r),
            ),
          ),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.resource, required this.unlocked, required this.onTap});

  final CourseResource resource;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: clayDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.35), lift: 0.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kClayRadiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Symbols.picture_as_pdf, size: 20, color: AppColors.onPrimaryFixedVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                      ),
                      if (resource.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          resource.subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(
                    unlocked ? Symbols.download : Symbols.lock,
                    size: 18,
                    color: unlocked ? AppColors.primary : AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.unlocked,
    required this.highlighted,
    required this.showPreviewTag,
    required this.completed,
    required this.onTap,
  });

  final CourseLesson lesson;
  final bool unlocked;
  final bool highlighted;
  final bool showPreviewTag;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = lesson.durationLabel;
    final kind = lesson.liveSessionId != null
        ? 'تسجيل لايف'
        : lesson.isYoutube
            ? 'فيديو يوتيوب'
            : 'فيديو';
    final meta = [if (duration != null) duration, kind].join(' • ');

    final (Color circleBg, Color circleFg, IconData circleIcon) = completed
        ? (AppColors.tertiaryContainer, AppColors.tertiary, Symbols.check)
        : !unlocked
            ? (AppColors.surfaceContainerHighest, AppColors.onSurfaceVariant, Symbols.lock)
            : highlighted
                ? (AppColors.primary, Colors.white, Symbols.play_arrow)
                : (AppColors.primaryFixedDim, AppColors.onPrimaryContainer, Symbols.play_arrow);

    final (String tag, Color tagBg, Color tagFg) = completed
        ? ('مكتمل', AppColors.tertiaryContainer, AppColors.onTertiaryContainer)
        : showPreviewTag
            ? ('معاينة مجانية', AppColors.secondaryFixed, AppColors.onSecondaryFixedVariant)
            : unlocked
                ? ('متاح للمشاهدة', AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant)
                : ('خاص بالمشتركات', AppColors.surfaceContainerHighest, AppColors.onSurfaceVariant);

    return Opacity(
      opacity: unlocked ? 1 : 0.9,
      child: Container(
        decoration: unlocked
            ? clayDecoration(lift: 0.5)
            : BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(kClayRadiusLg),
              ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(kClayRadiusLg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                      boxShadow: unlocked
                          ? [
                              BoxShadow(
                                color: circleBg.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(circleIcon, size: 20, color: circleFg, fill: 1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: unlocked ? AppColors.onSurface : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              meta,
                              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                tag,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tagFg),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    unlocked ? Symbols.chevron_right : Symbols.lock,
                    size: unlocked ? 22 : 20,
                    color: unlocked
                        ? (highlighted ? AppColors.primary : AppColors.outline)
                        : AppColors.outlineVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseBar extends ConsumerStatefulWidget {
  const _PurchaseBar({required this.course, required this.onSubscribe, required this.onContact});

  final Course course;
  final VoidCallback onSubscribe;
  final VoidCallback onContact;

  @override
  ConsumerState<_PurchaseBar> createState() => _PurchaseBarState();
}

class _PurchaseBarState extends ConsumerState<_PurchaseBar> {
  bool _buying = false;

  Future<void> _buy() async {
    setState(() => _buying = true);
    final result = await ref.read(coursePurchaseServiceProvider).buy(widget.course);
    if (!mounted) return;
    setState(() => _buying = false);
    if (result.outcome == CoursePurchaseOutcome.success) {
      ref.invalidate(courseAccessProvider(widget.course.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم فتح الدورة 🎉 استمتعي بالدروس')),
      );
    } else if (result.outcome != CoursePurchaseOutcome.cancelled && result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _choosePayment(String? storePrice) async {
    final course = widget.course;
    final choice = await showPaymentOptions(
      context,
      item: PaymentItem(
        kind: PaymentKind.course,
        id: course.id,
        title: course.title,
        priceLabel: course.priceLabel,
        priceUsd: course.priceUsd,
      ),
      storeLabel: storePrice == null ? null : 'Google Play — $storePrice',
    );
    if (!mounted) return;
    switch (choice) {
      case PaymentChoice.store:
        await _buy();
      case PaymentChoice.paidOnline:
        ref.invalidate(courseAccessProvider(course.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم فتح الدورة 🎉 استمتعي بالدروس')),
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final isSubscription = course.accessType == CourseAccessType.subscription;
    final storePrice = isSubscription ? null : ref.watch(courseStorePriceProvider(course)).valueOrNull;
    final settings = ref.watch(paymentSettingsProvider).valueOrNull ?? const PaymentSettings();
    final canPaypal = settings.paypalEnabled && course.priceUsd != null;
    final canBuy = storePrice != null || canPaypal || settings.canPayManually;
    final priceText = isSubscription
        ? 'ضمن الباقة'
        : storePrice ?? (course.priceLabel.isNotEmpty ? course.priceLabel : formatUsd(course.priceUsd)) ?? 'مدفوعة';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            priceText,
                            style: const TextStyle(
                              fontSize: 26,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          if (!isSubscription && course.oldPriceLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              course.oldPriceLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      ClayPill(
                        text: course.promoNote.isNotEmpty
                            ? course.promoNote
                            : isSubscription
                                ? 'كل الدروس مع الاشتراك ✨'
                                : 'دفعة واحدة وتفضل معاكي ✨',
                        fontSize: 11,
                        background: AppColors.secondaryFixed,
                        foreground: AppColors.onSecondaryFixed,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 210),
                        child: ClayChunkyButton(
                          label: isSubscription
                              ? 'اشتركي وافتحي الدورة'
                              : canBuy
                                  ? 'افتحي الدورة'
                                  : 'تواصلي على واتساب',
                          leadingIcon: isSubscription || canBuy ? Symbols.lock_open : Symbols.chat,
                          fontSize: 15,
                          busy: _buying,
                          onPressed: isSubscription
                              ? widget.onSubscribe
                              : canBuy
                                  ? () => _choosePayment(storePrice)
                                  : widget.onContact,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (course.guaranteeNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.verified_user, size: 15, color: AppColors.secondary, fill: 1),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          course.guaranteeNote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: widget.onContact,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Symbols.verified_user, size: 15, color: AppColors.secondary, fill: 1),
                label: const Text('عندك سؤال؟ تواصلي معانا على واتساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
