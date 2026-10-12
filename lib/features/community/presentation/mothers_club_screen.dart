import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../library/domain/library_age_band.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/club_feed_provider.dart';
import '../data/community_cloud_repository.dart';
import 'club_new_post_screen.dart';
import 'club_post_detail_screen.dart';
import 'widgets/club_shared.dart';

/// نادي الأمهات — المناقشات تتصنّف حسب عمر البيبي.
class MothersClubScreen extends ConsumerStatefulWidget {
  const MothersClubScreen({super.key});

  @override
  ConsumerState<MothersClubScreen> createState() => _MothersClubScreenState();
}

class _MothersClubScreenState extends ConsumerState<MothersClubScreen> {
  static const _looks = [
    (icon: Symbols.child_care, tint: AppColors.primaryFixed, iconColor: AppColors.primary),
    (icon: Symbols.spa, tint: AppColors.secondaryFixed, iconColor: AppColors.secondary),
    (icon: Symbols.toys, tint: AppColors.tertiaryFixed, iconColor: AppColors.tertiary),
    (icon: Symbols.sentiment_satisfied, tint: AppColors.primaryContainer, iconColor: AppColors.onPrimaryContainer),
    (icon: Symbols.favorite, tint: AppColors.secondaryContainer, iconColor: AppColors.onSecondaryContainer),
  ];

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _updateQuery(ClubFeedQuery Function(ClubFeedQuery q) change) {
    final notifier = ref.read(clubFeedQueryProvider.notifier);
    notifier.state = change(notifier.state);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _updateQuery((q) => q.copyWith(search: value.trim()));
    });
  }

  Future<void> _toggleSave(MothersClubPost post) async {
    try {
      final saved = await ref.read(mothersClubSavesProvider.notifier).toggle(post.id);
      if (!mounted) return;
      showClubSnack(context, saved ? 'اتحفظ — هتلاقيه في «المحفوظة» 🔖' : 'اتشال من المحفوظة');
      if (!saved && ref.read(clubFeedQueryProvider).savedOnly) ref.invalidate(mothersClubPostsProvider);
    } on ClubActionException catch (e) {
      if (mounted) showClubSnack(context, e.message);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر الحفظ');
    }
  }

  List<_ClubCategory> get _ageChips {
    return [
      const _ClubCategory(
        id: null,
        label: 'الكل',
        icon: Symbols.groups,
        tint: AppColors.primaryFixed,
        iconColor: AppColors.primary,
      ),
      for (var i = 0; i < LibraryAgeBand.values.length; i++)
        _ClubCategory(
          id: LibraryAgeBand.values[i].dbValue,
          label: LibraryAgeBand.values[i].label,
          icon: _looks[i % _looks.length].icon,
          tint: _looks[i % _looks.length].tint,
          iconColor: _looks[i % _looks.length].iconColor,
        ),
    ];
  }

  Future<void> _openNewPost() async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClubNewPostScreen(initialAgeId: ref.read(clubFeedQueryProvider).ageId)),
    );
    if (sent == true && mounted) {
      showClubSnack(context, 'وصلنا سؤالك 💛 هيظهر للأمهات بعد المراجعة');
    }
  }

  void _openPost(MothersClubPost post) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClubPostDetailScreen(post: post)));
  }

  Future<void> _openNotifications(List<MothersClubNotification> items) async {
    final repo = ref.read(communityCloudRepositoryProvider);
    final unread = items.where((n) => !n.isRead).map((n) => n.id).toList();
    final picked = await showModalBottomSheet<MothersClubNotification>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => _NotificationsSheet(items: items),
    );
    await repo.markNotificationsRead(unread);
    ref.invalidate(mothersClubNotificationsProvider);
    if (picked == null || !mounted) return;
    final post = await repo.fetchPost(picked.postId);
    if (!mounted) return;
    if (post == null) {
      showClubSnack(context, 'المنشور ده اتحذف');
      return;
    }
    _openPost(post);
  }

  Future<void> _toggleLike(MothersClubPost post) async {
    try {
      await ref.read(mothersClubLikesProvider.notifier).toggle(post.id);
    } on ClubActionException catch (e) {
      if (mounted) showClubSnack(context, e.message);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر تسجيل الإعجاب');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(clubFeedQueryProvider);
    final asyncFeed = ref.watch(mothersClubPostsProvider);
    ref.watch(mothersClubLikesProvider);
    final likes = ref.read(mothersClubLikesProvider.notifier);
    ref.watch(mothersClubSavesProvider);
    final saves = ref.read(mothersClubSavesProvider.notifier);
    final myId = ref.watch(communityCloudRepositoryProvider).currentUserId;
    final babyBand = babyAgeBandFromPrefs(ref.read(prefsServiceProvider));
    final chips = _ageChips;

    _ClubPost toCard(MothersClubPost p) => _ClubPost(
          source: p,
          author: p.displayAuthor,
          timeAgo: clubTimeAgo(p.createdAt),
          tag: LibraryAgeBand.tryFromDb(p.categoryId)?.label ?? '',
          tagBg: AppColors.secondaryContainer,
          tagFg: AppColors.onSecondaryContainer,
          title: p.title,
          body: p.body,
          likes: likes.countFor(p),
          comments: p.commentsCount,
          liked: likes.isLiked(p.id),
          saved: saves.isSaved(p.id),
          mine: myId != null && p.authorId == myId,
          avatarTint: AppColors.tertiaryContainer,
        );

    final feedSlivers = asyncFeed.when<List<Widget>>(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ],
      error: (_, __) => [
        SliverToBoxAdapter(
          child: _EmptyClub(message: 'تعذّر تحميل النادي — اسحبي لتحت عشان تحاولي تاني'),
        ),
      ],
      data: (feed) {
        if (feed.posts.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: _EmptyClub(
                message: query.search.isNotEmpty
                    ? 'مفيش مناقشات فيها «${query.search}»'
                    : query.savedOnly
                        ? 'لسه ماحفظتيش أي منشور — دوسي على 🔖 في أي منشور عشان ترجعيله بعدين'
                        : query.sort == ClubSort.unanswered
                            ? 'كل الأسئلة اتردّ عليها 👏'
                            : query.ageId != null
                                ? 'لسه مفيش أسئلة في السن ده — كوني أول أم تسأل 💛'
                                : 'كوني أول أم تسأل في النادي 💛',
                onAsk: query.search.isEmpty && !query.savedOnly ? _openNewPost : null,
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList.separated(
              itemCount: feed.posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final p = feed.posts[i];
                return _PostCard(
                  post: toCard(p),
                  onTap: () => _openPost(p),
                  onLike: () => _toggleLike(p),
                  onSave: () => _toggleSave(p),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Center(
                child: feed.loadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : feed.hasMore
                        ? TextButton(
                            onPressed: () => ref.read(mothersClubPostsProvider.notifier).loadMore(),
                            child: const Text('اعرضي أكتر'),
                          )
                        : Text(
                            'وصلتي لآخر المناقشات ✨',
                            style: theme.textTheme.labelLarge?.copyWith(color: AppColors.outline),
                          ),
              ),
            ),
          ),
        ];
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'نادي الأمهات',
        showStars: true,
        starsCount: 12,
        onBack: () => context.pop(),
      ),
      floatingActionButton: _NewPostFab(onPressed: _openNewPost),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(mothersClubPostsProvider);
                ref.invalidate(mothersClubLikesProvider);
                ref.invalidate(mothersClubSavesProvider);
                ref.invalidate(mothersClubNotificationsProvider);
                await ref.read(mothersClubPostsProvider.future);
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 500) ref.read(mothersClubPostsProvider.notifier).loadMore();
                  return false;
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _RepliesBanner(onOpen: _openNotifications)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      sliver: SliverToBoxAdapter(child: _SearchField(onChanged: _onSearchChanged)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'حسب عمر البيبي',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (babyBand != null && query.ageId == babyBand.dbValue)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'بنعرضلك أسئلة سن بيبيك (${babyBand.label}) — اختاري «الكل» لكل الأسئلة',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          itemCount: chips.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) => _CategoryCard(
                            category: chips[i],
                            selected: chips[i].id == query.ageId,
                            onTap: () => _updateQuery((q) => q.copyWith(ageId: chips[i].id)),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                          children: [
                            for (final (sort, label) in const [
                              (ClubSort.newest, 'الأحدث'),
                              (ClubSort.popular, 'الأكثر تفاعلاً'),
                              (ClubSort.unanswered, 'مستنية رد'),
                            ])
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 8),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: !query.savedOnly && query.sort == sort,
                                  selectedColor: AppColors.primaryFixed,
                                  onSelected: (_) => _updateQuery((q) => q.copyWith(sort: sort, savedOnly: false)),
                                ),
                              ),
                            ChoiceChip(
                              avatar: Icon(Symbols.bookmark, size: 18, fill: query.savedOnly ? 1 : 0),
                              label: const Text('المحفوظة'),
                              selected: query.savedOnly,
                              selectedColor: AppColors.primaryFixed,
                              onSelected: (v) => _updateQuery((q) => q.copyWith(savedOnly: v, sort: ClubSort.newest)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ...feedSlivers,
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

/// «عندك ردود جديدة» — only shows when there are unread notifications.
class _RepliesBanner extends ConsumerWidget {
  const _RepliesBanner({required this.onOpen});

  final ValueChanged<List<MothersClubNotification>> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(mothersClubNotificationsProvider).valueOrNull ?? const [];
    final unread = items.where((n) => !n.isRead).length;
    if (unread == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Material(
        color: AppColors.primaryFixed,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: () => onOpen(items),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Symbols.notifications_active, color: AppColors.primary, fill: 1),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    unread == 1 ? 'عندك تحديث جديد على أسئلتك 💬' : 'عندك $unread تحديثات جديدة على أسئلتك 💬',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const Icon(Symbols.chevron_left, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.items});

  final List<MothersClubNotification> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('تحديثات أسئلتك', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final n = items[i];
                  return ListTile(
                    leading: Icon(
                      switch (n.kind) {
                        'expert_reply' => Symbols.verified,
                        'approved' => Symbols.check_circle,
                        _ => Symbols.chat_bubble,
                      },
                      color: n.kind == 'expert_reply' ? const Color(0xFF1E6B3A) : AppColors.primary,
                      fill: 1,
                    ),
                    title: Text(
                      n.message,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w800),
                    ),
                    subtitle: Text(clubTimeAgo(n.createdAt)),
                    trailing: n.isRead
                        ? null
                        : const CircleAvatar(radius: 5, backgroundColor: AppColors.primary),
                    onTap: () => Navigator.pop(context, n),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyClub extends StatelessWidget {
  const _EmptyClub({required this.message, this.onAsk});

  final String message;
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 100),
      child: Column(
        children: [
          const Icon(Symbols.forum, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
          ),
          if (onAsk != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAsk,
              icon: const Icon(Symbols.edit),
              label: const Text('اسألي دلوقتي'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.brMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            offset: const Offset(3, 3),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            offset: const Offset(-2, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        textAlign: TextAlign.right,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'ابحثي في المناقشات...',
          hintStyle: AppTextField.hintStyle(Theme.of(context)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const Icon(Symbols.search, color: AppColors.outline),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.selected, required this.onTap});

  final _ClubCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TactileClayCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      color: category.tint.withValues(alpha: selected ? 0.85 : 0.35),
      borderRadius: AppRadius.brLg,
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.05),
                    offset: const Offset(2, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(category.icon, size: 32, color: category.iconColor, fill: 1),
            ),
            const SizedBox(height: 10),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.onPrimaryFixed : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap, required this.onLike, required this.onSave});

  final _ClubPost post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = post.source;

    return TactileClayCard(
      onTap: onTap,
      color: post.muted
          ? AppColors.surfaceContainerLow
          : AppColors.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: post.avatarTint.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.soft,
                      ),
                      child: source.isAnonymous
                          ? const Icon(Symbols.visibility_off, color: AppColors.onTertiaryContainer)
                          : const AppLogoAvatar(size: 44, imageAsset: AppAssets.logoBaby),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            post.timeAgo,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.outline,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (post.tag.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: post.tagBg,
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Text(
                    post.tag,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: post.tagFg,
                    ),
                  ),
                ),
            ],
          ),
          if (source.isPinned || source.hasExpertReply) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (source.isPinned)
                  const ClubStatusPill(
                    text: 'مثبّت',
                    icon: Symbols.push_pin,
                    background: AppColors.primaryFixed,
                    foreground: AppColors.primary,
                  ),
                if (source.hasExpertReply)
                  const ClubStatusPill(
                    text: 'ردّت الأخصائية',
                    icon: Symbols.verified,
                    background: Color(0xFFDDF2E3),
                    foreground: Color(0xFF1E6B3A),
                  ),
              ],
            ),
          ],
          if (post.mine && !source.isPublished) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: source.isRejected
                  ? const ClubStatusPill(
                      text: 'ماتنشرش',
                      icon: Symbols.block,
                      background: AppColors.errorContainer,
                      foreground: AppColors.onErrorContainer,
                    )
                  : const ClubStatusPill(
                      text: 'قيد المراجعة',
                      icon: Symbols.hourglass_top,
                      background: AppColors.tertiaryContainer,
                      foreground: AppColors.onTertiaryContainer,
                    ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            post.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            post.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (source.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClubPostImage(url: source.imageUrl!, height: 160),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                borderRadius: AppRadius.brFull,
                onTap: source.isPublished ? onLike : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.favorite,
                        size: 22,
                        fill: post.liked ? 1 : 0,
                        color: post.liked ? AppColors.error : AppColors.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likes}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: post.liked ? AppColors.error : AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Symbols.chat_bubble, size: 22, color: AppColors.outline),
              const SizedBox(width: 6),
              Text(
                '${post.comments}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.outline,
                ),
              ),
              if (source.isPublished) ...[
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: AppRadius.brFull,
                  onTap: onSave,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Symbols.bookmark,
                      size: 22,
                      fill: post.saved ? 1 : 0,
                      color: post.saved ? AppColors.primary : AppColors.outline,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                post.comments == 0 ? 'ردّي على السؤال' : 'اقري الردود',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const Icon(Symbols.chevron_left, size: 20, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewPostFab extends StatefulWidget {
  const _NewPostFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_NewPostFab> createState() => _NewPostFabState();
}

class _NewPostFabState extends State<_NewPostFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 60,
        height: 60,
        transform: Matrix4.identity()
          ..translateByDouble(0, _pressed ? 4.0 : 0.0, 0, 1),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: _pressed
              ? AppShadows.soft
              : [
                  BoxShadow(
                    color: AppColors.primaryDim.withValues(alpha: 0.45),
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    offset: const Offset(0, 10),
                    blurRadius: 20,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: const Icon(Symbols.add, color: AppColors.onPrimary, size: 32),
      ),
    );
  }
}
class _ClubCategory {
  const _ClubCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String? id;
  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;
}

class _ClubPost {
  const _ClubPost({
    required this.source,
    required this.mine,
    required this.saved,
    required this.author,
    required this.timeAgo,
    required this.tag,
    required this.tagBg,
    required this.tagFg,
    required this.title,
    required this.body,
    required this.likes,
    required this.comments,
    required this.liked,
    required this.avatarTint,
  });

  final MothersClubPost source;
  final bool mine;
  final bool saved;
  final String author;
  final String timeAgo;
  final String tag;
  final Color tagBg;
  final Color tagFg;
  final String title;
  final String body;
  final int likes;
  final int comments;
  final bool liked;
  final Color avatarTint;
  final bool muted = false;
}

