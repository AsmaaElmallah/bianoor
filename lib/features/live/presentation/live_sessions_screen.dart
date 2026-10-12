import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/presentation/course_detail_screen.dart';
import '../data/live_repository.dart';
import '../domain/live_session.dart';
import 'live_room_screen.dart';

Future<void> openLiveSession(BuildContext context, WidgetRef ref, LiveSession session) async {
  if (session.status == LiveStatus.scheduled) {
    final when = session.scheduleLabel;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(session.showAsEnded
            ? 'اللايف انتهى'
            : when != null
                ? 'اللايف هيبدأ $when، ارجعي في الميعاد 🌸'
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
