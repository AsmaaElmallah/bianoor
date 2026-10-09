import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/presentation/course_detail_screen.dart';
import '../../courses/presentation/widgets/course_access_badge.dart';
import '../data/live_repository.dart';
import '../domain/live_session.dart';
import 'live_room_screen.dart';

Future<void> openLiveSession(BuildContext context, WidgetRef ref, LiveSession session) async {
  if (session.status == LiveStatus.scheduled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(session.scheduleLabel != null
            ? 'اللايف هيبدأ ${session.scheduleLabel}، ارجعي في الميعاد 🌸'
            : 'اللايف لسه ما بدأش'),
      ),
    );
    return;
  }
  if (session.status == LiveStatus.ended && !session.hasRecording) {
    final courseId = session.courseId;
    if (courseId != null) {
      final courses = await ref.read(coursesProvider.future);
      if (!context.mounted) return;
      final course = courses.where((c) => c.id == courseId).firstOrNull;
      if (course != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => CourseDetailScreen(course: course)),
        );
        return;
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('التسجيل هينزل قريب')),
    );
    return;
  }

  final hasAccess = await ref.read(liveAccessProvider(session.id).future);
  if (!context.mounted) return;
  if (!hasAccess) {
    _showLocked(context, ref, session);
    return;
  }
  if (session.status == LiveStatus.live) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LiveRoomScreen(session: session)),
    );
    ref.invalidate(liveSessionsProvider);
  } else {
    await openYoutubeFullscreen(context, videoId: session.recordingYoutubeId);
  }
}

void _showLocked(BuildContext context, WidgetRef ref, LiveSession session) {
  final isCourse = session.accessType == LiveAccessType.course;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('اللايف ده مقفول'),
      content: Text(isCourse
          ? 'اللايف ده لمشتركات الدورة بتاعته. افتحي الدورة الأول وبعدين ارجعي.'
          : 'اللايف ده للمشتركات في الباقة. اشتركي علشان تحضري كل اللايفات.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('لاحقاً')),
        FilledButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            if (!isCourse) {
              context.push(AppRoutes.subscription);
              return;
            }
            final courses = await ref.read(coursesProvider.future);
            if (!context.mounted) return;
            final course = courses.where((c) => c.id == session.courseId).firstOrNull;
            if (course != null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => CourseDetailScreen(course: course)),
              );
            }
          },
          child: Text(isCourse ? 'افتحي الدورة' : 'اشتركي الآن'),
        ),
      ],
    ),
  );
}

/// Upcoming lives and recordings, shown as a tab inside the courses screen.
class LiveSessionsTab extends ConsumerWidget {
  const LiveSessionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSessions = ref.watch(liveSessionsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(liveSessionsProvider.future),
      child: asyncSessions.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const _EmptyList('تعذّر تحميل اللايفات، اسحبي لتحت للمحاولة تاني.'),
        data: (sessions) {
          final upcoming = sessions.where((s) => s.status == LiveStatus.scheduled).toList();
          final past = sessions.where((s) => s.status == LiveStatus.ended).toList().reversed.toList();
          if (upcoming.isEmpty && past.isEmpty) {
            return const _EmptyList('مفيش لايفات جاية دلوقتي، هنعلن عن اللايف الجاي قريب 🌸');
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              if (upcoming.isNotEmpty) ...[
                const _SectionTitle('اللايفات الجاية'),
                for (final s in upcoming) LiveCard(session: s, onTap: () => openLiveSession(context, ref, s)),
              ],
              if (past.isNotEmpty) ...[
                const _SectionTitle('التسجيلات'),
                for (final s in past) LiveCard(session: s, onTap: () => openLiveSession(context, ref, s)),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Highlighted card for a session that is broadcasting right now.
class LiveNowBanner extends ConsumerWidget {
  const LiveNowBanner({super.key, required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.errorContainer, AppColors.surfaceContainerLowest],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LiveBadge(),
          const SizedBox(height: 10),
          Text(
            session.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (session.instructorName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Symbols.person, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  session.instructorName,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => openLiveSession(context, ref, session),
              icon: const Icon(Symbols.headphones),
              label: const Text('ادخلي اللايف'),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, this.label = 'مباشر الآن'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Icon(Symbols.live_tv, size: 56, color: AppColors.primary),
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

class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.session, required this.onTap});

  final LiveSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (badgeText, badgeColor) = switch (session.status) {
      LiveStatus.live => ('● مباشر', AppColors.error),
      LiveStatus.scheduled => (session.scheduleLabel ?? 'قريباً', AppColors.primary),
      LiveStatus.ended => (session.hasRecording ? 'شاهدي التسجيل' : 'انتهى', AppColors.onSurfaceVariant),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 110,
                height: 90,
                child: session.coverUrl != null
                    ? CourseCover(url: session.coverUrl)
                    : Container(
                        color: AppColors.primaryContainer,
                        child: const Icon(Symbols.videocam, color: AppColors.primary, size: 36),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (session.instructorName.isNotEmpty)
                        Text(
                          session.instructorName,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: theme.textTheme.labelSmall?.copyWith(color: badgeColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
