import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_art.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/mascot_message.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/presentation/course_detail_screen.dart';
import '../../live/data/live_repository.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/club_feed_provider.dart';
import '../data/community_cloud_repository.dart';
import 'club_new_post_screen.dart';
import 'club_post_detail_screen.dart';
import 'widgets/club_post_card.dart';
import 'widgets/club_shared.dart';

/// جروب في نادي الأمهات (مثلاً جروب دورة): معلومات + مواعيد + نقاشات.
class ClubGroupScreen extends ConsumerWidget {
  const ClubGroupScreen({super.key, required this.groupId, this.initial});

  final String groupId;
  final MothersClubGroup? initial;

  Future<void> _toggleJoin(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(myClubGroupsProvider.notifier);
    final joining = !notifier.isMember(groupId);
    try {
      await notifier.toggle(groupId);
      ref.invalidate(clubGroupProvider(groupId));
      ref.invalidate(clubGroupsProvider);
      if (context.mounted) {
        showClubSnack(context, joining ? 'انضميتي للجروب 💛 هيوصلك أي إعلان جديد' : 'خرجتي من الجروب');
      }
    } on ClubActionException catch (e) {
      if (context.mounted) showClubSnack(context, e.message);
    } catch (_) {
      if (context.mounted) showClubSnack(context, 'تعذّر، حاولي تاني');
    }
  }

  Future<void> _write(BuildContext context, MothersClubGroup group) async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClubNewPostScreen(groupId: group.id, groupTitle: group.title)),
    );
    if (sent == true && context.mounted) showClubSnack(context, 'اتنشر في الجروب 👏');
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref, MothersClubPost post) async {
    try {
      await ref.read(mothersClubLikesProvider.notifier).toggle(post.id);
    } catch (_) {
      if (context.mounted) showClubSnack(context, 'تعذّر تسجيل الإعجاب');
    }
  }

  Future<void> _toggleSave(BuildContext context, WidgetRef ref, MothersClubPost post) async {
    try {
      final saved = await ref.read(mothersClubSavesProvider.notifier).toggle(post.id);
      if (context.mounted) showClubSnack(context, saved ? 'اتحفظ 🔖' : 'اتشال من المحفوظة');
    } catch (_) {
      if (context.mounted) showClubSnack(context, 'تعذّر الحفظ');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGroup = ref.watch(clubGroupProvider(groupId));
    final group = asyncGroup.valueOrNull ?? initial;

    Widget body;
    if (group == null) {
      body = asyncGroup.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Center(
              child: MascotMessage(
                title: asyncGroup.hasError ? 'النت فصل شوية' : 'الجروب ده مش موجود',
                message: asyncGroup.hasError ? 'اتأكدي من الإنترنت وجربي تاني.' : 'ممكن الإدارة قفلته.',
              ),
            );
    } else {
      body = _GroupBody(
        group: group,
        onJoin: () => _toggleJoin(context, ref),
        onWrite: () => _write(context, group),
        onLike: (p) => _toggleLike(context, ref, p),
        onSave: (p) => _toggleSave(context, ref, p),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: group?.title ?? 'الجروب', onBack: () => Navigator.of(context).pop()),
      floatingActionButton: group == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _write(context, group),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              icon: const Icon(Symbols.edit),
              label: const Text('اكتبي في الجروب', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(clubGroupProvider(groupId));
                ref.invalidate(clubGroupPostsProvider(groupId));
                ref.invalidate(myClubGroupsProvider);
                await ref.read(clubGroupPostsProvider(groupId).future);
              },
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupBody extends ConsumerWidget {
  const _GroupBody({
    required this.group,
    required this.onJoin,
    required this.onWrite,
    required this.onLike,
    required this.onSave,
  });

  final MothersClubGroup group;
  final VoidCallback onJoin;
  final VoidCallback onWrite;
  final ValueChanged<MothersClubPost> onLike;
  final ValueChanged<MothersClubPost> onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncPosts = ref.watch(clubGroupPostsProvider(group.id));
    final isMember = ref.watch(myClubGroupsProvider).valueOrNull?.contains(group.id) ?? false;
    ref.watch(mothersClubLikesProvider);
    final likes = ref.read(mothersClubLikesProvider.notifier);
    ref.watch(mothersClubSavesProvider);
    final saves = ref.read(mothersClubSavesProvider.notifier);
    final myId = ref.watch(communityCloudRepositoryProvider).currentUserId;

    ClubPostView toCard(MothersClubPost p) => ClubPostView(
          source: p,
          author: p.displayAuthor,
          timeAgo: clubTimeAgo(p.createdAt),
          tag: p.isPinned ? '📌 مثبّت' : '',
          tagBg: AppColors.primaryFixed,
          tagFg: AppColors.onPrimaryFixed,
          title: p.title,
          body: p.body,
          likes: likes.countFor(p),
          comments: p.commentsCount,
          liked: likes.isLiked(p.id),
          saved: saves.isSaved(p.id),
          mine: myId != null && p.authorId == myId,
          avatarTint: AppColors.tertiaryContainer,
        );

    final posts = asyncPosts.valueOrNull ?? const <MothersClubPost>[];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        _Header(group: group, isMember: isMember, onJoin: onJoin),
        if (group.infoNote.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          TactileClayCard(
            color: AppColors.primaryFixed.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(AppArt.memo, width: 28, height: 28),
                    const SizedBox(width: 8),
                    Text('عن الجروب', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(group.infoNote, style: theme.textTheme.bodyMedium?.copyWith(height: 1.55)),
              ],
            ),
          ),
        ],
        if (group.courseId != null) ...[
          const SizedBox(height: 16),
          _CourseCard(courseId: group.courseId!),
        ],
        const SizedBox(height: 24),
        Text('النقاشات', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (asyncPosts.isLoading && posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (asyncPosts.hasError && posts.isEmpty)
          MascotMessage.error(onAction: () => ref.invalidate(clubGroupPostsProvider(group.id)))
        else if (posts.isEmpty)
          MascotMessage(
            title: 'لسه مفيش نقاشات',
            message: 'كوني أول واحدة تكتب في الجروب 💛',
            actionLabel: 'اكتبي دلوقتي',
            onAction: onWrite,
          )
        else
          for (final p in posts) ...[
            ClubPostCard(
              post: toCard(p),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ClubPostDetailScreen(post: p)),
              ),
              onLike: () => onLike(p),
              onSave: () => onSave(p),
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.group, required this.isMember, required this.onJoin});

  final MothersClubGroup group;
  final bool isMember;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TactileClayCard(
      child: Column(
        children: [
          Image.asset(AppArt.forKey(group.iconKey), width: 84, height: 84),
          const SizedBox(height: 8),
          Text(
            group.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (group.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              group.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${group.membersCount} عضوة · ${group.postsCount} نقاش',
            style: theme.textTheme.labelLarge?.copyWith(color: AppColors.outline, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: isMember
                ? OutlinedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Symbols.check_circle, fill: 1),
                    label: const Text('إنتي في الجروب — دوسي عشان تخرجي'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Symbols.group_add),
                    label: const Text('انضمي للجروب', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                    ),
                  ),
          ),
          if (!isMember) ...[
            const SizedBox(height: 6),
            Text(
              'لما تنضمي هيوصلك إشعار بأي إعلان جديد من الإدارة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// The linked course + its next live with a countdown.
class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final course = ref.watch(coursesProvider).valueOrNull?.where((c) => c.id == courseId).firstOrNull;
    if (course == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final upcoming = (ref.watch(liveSessionsProvider).valueOrNull ?? const [])
        .where((s) => s.courseId == courseId && !s.showAsEnded && s.scheduledAt != null)
        .toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final next = upcoming.where((s) => s.scheduledAt!.isAfter(now.subtract(const Duration(hours: 2)))).firstOrNull;

    return TactileClayCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CourseDetailScreen(course: course)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(AppArt.graduationCap, width: 36, height: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  course.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Symbols.chevron_left, color: AppColors.primary),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Image.asset(AppArt.calendar, width: 24, height: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'اللايف الجاي: ${next.title}${next.scheduleLabel == null ? '' : '\n${next.scheduleLabel}'}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LiveCountdownPill(at: next.scheduledAt),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'افتحي الدورة عشان تشوفي الدروس والمواعيد',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
