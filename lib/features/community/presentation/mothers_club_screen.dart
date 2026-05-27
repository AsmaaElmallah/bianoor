import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/content/content_fetch_result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/mothers_club_provider.dart';
import '../domain/mothers_club_models.dart';
import 'widgets/mothers_club_post_image.dart';

/// نادي الأمهات — قائمة منشورات من Supabase مع fallback محلي.
class MothersClubScreen extends ConsumerStatefulWidget {
  const MothersClubScreen({super.key});

  @override
  ConsumerState<MothersClubScreen> createState() => _MothersClubScreenState();
}

class _MothersClubScreenState extends ConsumerState<MothersClubScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(mothersClubFeedProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    ref.read(mothersClubFeedProvider.notifier).applySearch(value);
  }

  void _selectCategory(String? categoryId) {
    final current = ref.read(mothersClubFeedFilterProvider);
    ref.read(mothersClubFeedFilterProvider.notifier).state = MothersClubFeedFilter(
      categoryId: categoryId,
      searchQuery: current.searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(mothersClubFeedProvider);
    final categoriesAsync = ref.watch(mothersClubCategoriesProvider);
    final selectedCategory = ref.watch(mothersClubFeedFilterProvider).categoryId;
    final searchQuery = ref.watch(mothersClubFeedFilterProvider).searchQuery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'نادي الأمهات',
        showStars: true,
        starsCount: 12,
        onBack: () => context.pop(),
      ),
      floatingActionButton: _NewPostFab(
        onPressed: () => context.push(AppRoutes.mothersClubNewPost),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(mothersClubFeedProvider.notifier).refresh();
                ref.invalidate(mothersClubCategoriesProvider);
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  feedAsync.when(
                    loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    data: (feed) {
                      if (feed.source != ContentFetchSource.remote &&
                          feed.source != ContentFetchSource.supabaseDisabled) {
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: _SourceBanner(feed: feed),
                          ),
                        );
                      }
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    },
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التصنيفات',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _selectCategory(null),
                            child: Text(
                              selectedCategory == null ? 'الكل' : 'رؤية الكل',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  categoriesAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 168,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    data: (result) => SliverToBoxAdapter(
                      child: SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          itemCount: result.data.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final cat = result.data[i];
                            final selected = selectedCategory == cat.id;
                            return _CategoryCard(
                              category: cat,
                              selected: selected,
                              onTap: () => _selectCategory(
                                selected ? null : cat.id,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(
                            'أحدث المناقشات',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  feedAsync.when(
                    loading: () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('تعذر التحميل: $e')),
                    ),
                    data: (feed) {
                      final posts = feed.postsForQuery(searchQuery);
                      if (posts.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'لا منشورات بعد — كوني أول من يشارك.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              if (i >= posts.length) {
                                return feed.loadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox(height: 8);
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PostCard(
                                  post: posts[i],
                                  onTap: () => context.push(
                                    AppRoutes.mothersClubPostPath(posts[i].id),
                                  ),
                                ),
                              );
                            },
                            childCount: posts.length + (feed.hasMore ? 1 : 0),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBanner extends StatelessWidget {
  const _SourceBanner({required this.feed});

  final MothersClubFeedState feed;

  @override
  Widget build(BuildContext context) {
    final msg = switch (feed.source) {
      ContentFetchSource.remoteEmpty =>
        'متصل — لا منشورات منشورة بعد. يُعرض محتوى تجريبي.',
      ContentFetchSource.errorFallback =>
        feed.errorMessage ?? 'تعذر الجلب من Supabase — يُعرض محتوى محلي.',
      _ => 'تحققي من الاتصال بـ Supabase',
    };

    return TactileClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.secondaryContainer.withValues(alpha: 0.4),
      child: Text(
        msg,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
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
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحثي عن مواضيع تهمك...',
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
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final MothersClubCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TactileClayCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.55)
          : category.tint.withValues(alpha: 0.35),
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
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final MothersClubPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColors = post.tagColors;

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
                        color: AppColors.tertiaryContainer.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.soft,
                      ),
                      child: const AppLogoAvatar(
                        size: 44,
                        imageAsset: AppAssets.logoBaby,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            post.timeAgoLabel,
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
                    color: tagColors.$1,
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Text(
                    post.tag,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tagColors.$2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            MothersClubPostImage(imageUrl: post.imageUrl!),
          ],
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Symbols.favorite,
                size: 22,
                fill: post.likedByMe ? 1 : 0,
                color: post.likedByMe ? AppColors.error : AppColors.outline,
              ),
              const SizedBox(width: 6),
              Text(
                '${post.likeCount}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: post.likedByMe ? AppColors.error : AppColors.outline,
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Symbols.chat_bubble, size: 22, color: AppColors.outline),
              const SizedBox(width: 6),
              Text(
                '${post.commentCount}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.outline,
                ),
              ),
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
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
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
