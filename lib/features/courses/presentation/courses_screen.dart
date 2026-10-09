import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../live/data/live_repository.dart';
import '../../live/domain/live_session.dart';
import '../../live/presentation/live_sessions_screen.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';
import 'course_detail_screen.dart';
import 'widgets/course_access_badge.dart';

/// Courses and live sessions together: a live-now banner on top, then two tabs.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveNow = (ref.watch(liveSessionsProvider).valueOrNull ?? const <LiveSession>[])
        .where((s) => s.status == LiveStatus.live)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          title: const Text('الدورات واللايف'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            for (final session in liveNow)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: LiveNowBanner(session: session),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _SegmentedTabs(),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _CoursesTab(),
                  LiveSessionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: AppColors.primaryDim,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: style,
        unselectedLabelStyle: style,
        tabs: const [
          Tab(height: 40, text: 'الدورات'),
          Tab(height: 40, text: 'اللايفات'),
        ],
      ),
    );
  }
}

class _CoursesTab extends ConsumerWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCourses = ref.watch(coursesProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(liveSessionsProvider);
        ref.invalidate(coursesProvider);
        await ref.read(coursesProvider.future);
      },
      child: asyncCourses.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const _Message(
          icon: Symbols.cloud_off,
          text: 'تعذّر تحميل الدورات، اسحبي لتحت للمحاولة تاني.',
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return const _Message(
              icon: Symbols.school,
              text: 'الدورات هتنزل قريب، تابعينا 🌸',
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _CourseCard(course: courses[index]),
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => CourseDetailScreen(course: course)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CourseCover(url: course.coverUrl),
                  PositionedDirectional(
                    top: 10,
                    start: 10,
                    child: CourseAccessBadge(course: course),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (course.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      course.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      if (course.instructorName.isNotEmpty)
                        _Meta(icon: Symbols.person, text: course.instructorName),
                      _Meta(icon: Symbols.play_circle, text: '${course.lessonCount} درس'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 56, color: AppColors.primary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
