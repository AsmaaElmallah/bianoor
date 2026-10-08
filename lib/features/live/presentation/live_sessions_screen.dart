import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/youtube/youtube_fullscreen_player.dart';
import '../../courses/presentation/courses_screen.dart';
import '../../courses/presentation/widgets/course_access_badge.dart';
import '../data/live_repository.dart';
import '../domain/live_session.dart';
import 'live_room_screen.dart';

class LiveSessionsScreen extends ConsumerWidget {
  const LiveSessionsScreen({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, LiveSession session) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التسجيل هينزل قريب')),
      );
      return;
    }

    final hasAccess = await ref.read(liveAccessProvider(session.id).future);
    if (!context.mounted) return;
    if (!hasAccess) {
      _showLocked(context, session);
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

  void _showLocked(BuildContext context, LiveSession session) {
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
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (isCourse) {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CoursesScreen()));
              } else {
                context.push(AppRoutes.subscription);
              }
            },
            child: Text(isCourse ? 'الدورات' : 'اشتركي الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSessions = ref.watch(liveSessionsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اللايف'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(liveSessionsProvider.future),
        child: asyncSessions.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => ListView(
            children: const [
              Padding(
                padding: EdgeInsets.all(32),
                child: Text('تعذّر تحميل اللايفات، اسحبي لتحت للمحاولة تاني.', textAlign: TextAlign.center),
              ),
            ],
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('مفيش لايفات دلوقتي، هنعلن عن اللايف الجاي قريب 🌸', textAlign: TextAlign.center),
                  ),
                ],
              );
            }
            final live = sessions.where((s) => s.status == LiveStatus.live).toList();
            final upcoming = sessions.where((s) => s.status == LiveStatus.scheduled).toList();
            final past = sessions.where((s) => s.status == LiveStatus.ended).toList().reversed.toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (live.isNotEmpty) ...[
                  const _SectionTitle('مباشر الآن'),
                  for (final s in live) _LiveCard(session: s, onTap: () => _open(context, ref, s)),
                ],
                if (upcoming.isNotEmpty) ...[
                  const _SectionTitle('اللايفات الجاية'),
                  for (final s in upcoming) _LiveCard(session: s, onTap: () => _open(context, ref, s)),
                ],
                if (past.isNotEmpty) ...[
                  const _SectionTitle('التسجيلات'),
                  for (final s in past) _LiveCard(session: s, onTap: () => _open(context, ref, s)),
                ],
              ],
            );
          },
        ),
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

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.session, required this.onTap});

  final LiveSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (badgeText, badgeColor) = switch (session.status) {
      LiveStatus.live => ('● مباشر', Colors.red),
      LiveStatus.scheduled => (session.scheduleLabel ?? 'قريباً', AppColors.primary),
      LiveStatus.ended => (session.hasRecording ? 'شاهدي التسجيل' : 'انتهى', AppColors.outline),
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
