import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';

/// نادي الأمهات — مطابق لتصميم `nady-mothers/code.html` بلوحة Royal.
class MothersClubScreen extends StatelessWidget {
  const MothersClubScreen({super.key});

  static const _categories = [
    _ClubCategory(
      label: 'نصائح التربية',
      icon: Symbols.child_care,
      tint: AppColors.primaryFixed,
      iconColor: AppColors.primary,
    ),
    _ClubCategory(
      label: 'رحلات قرآنية',
      icon: Symbols.menu_book,
      tint: AppColors.tertiaryFixed,
      iconColor: AppColors.tertiary,
    ),
    _ClubCategory(
      label: 'التغذية',
      icon: Symbols.restaurant,
      tint: AppColors.secondaryFixed,
      iconColor: AppColors.secondary,
    ),
    _ClubCategory(
      label: 'أنشطة',
      icon: Symbols.toys,
      tint: AppColors.primaryContainer,
      iconColor: AppColors.onPrimaryContainer,
    ),
  ];

  static const _posts = [
    _ClubPost(
      author: 'سارة أحمد',
      timeAgo: 'منذ ٢ ساعة',
      tag: '#الختمة_الأولى',
      tagBg: AppColors.secondaryContainer,
      tagFg: AppColors.onSecondaryContainer,
      title: 'كيف بدأتم تعليم أطفالكم السور القصيرة؟',
      body:
          'بدأت مع طفلي ذو الثلاث سنوات في تحفيظ سورة الفاتحة والإخلاص، وجدت أن التكرار وقت اللعب هو الأكثر فعالية. هل لديكم تجارب أخرى؟',
      likes: 24,
      comments: 12,
      liked: false,
      avatarTint: AppColors.tertiaryContainer,
    ),
    _ClubPost(
      author: 'ليلى محمد',
      timeAgo: 'منذ ٥ ساعات',
      tag: '#تغذية_الطفل',
      tagBg: AppColors.primaryFixed,
      tagFg: AppColors.onPrimaryFixedVariant,
      title: 'وجبات خفيفة وصحية للمدرسة',
      body:
          'أبحث عن أفكار لوجبات خفيفة لا تستغرق وقتاً طويلاً في التحضير وتكون غنية بالعناصر الغذائية الضرورية لنمو الطفل.',
      likes: 45,
      comments: 8,
      liked: true,
      avatarTint: AppColors.primaryContainer,
      muted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'نادي الأمهات',
        showStars: true,
        starsCount: 12,
        onBack: () => context.pop(),
      ),
      floatingActionButton: _NewPostFab(onPressed: () {}),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchField(),
                  ),
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
                          onPressed: () {},
                          child: Text(
                            'رؤية الكل',
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
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 168,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _CategoryCard(
                        category: _categories[i],
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) => _PostCard(post: _posts[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
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
  const _CategoryCard({required this.category});

  final _ClubCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TactileClayCard(
      onTap: () {},
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      color: category.tint.withValues(alpha: 0.35),
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
  const _PostCard({required this.post});

  final _ClubPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TactileClayCard(
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
                      child: const AppLogoAvatar(size: 44, imageAsset: AppAssets.logoBaby),
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
          const SizedBox(height: 12),
          Row(
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
              const SizedBox(width: 20),
              const Icon(Symbols.chat_bubble, size: 22, color: AppColors.outline),
              const SizedBox(width: 6),
              Text(
                '${post.comments}',
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
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;
}

class _ClubPost {
  const _ClubPost({
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
    this.muted = false,
  });

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
  final bool muted;
}
