import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/app_logo_avatar.dart';
import '../../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../data/community_cloud_repository.dart';
import 'club_shared.dart';
class ClubPostCard extends StatelessWidget {
  const ClubPostCard({super.key, required this.post, required this.onTap, required this.onLike, required this.onSave});

  final ClubPostView post;
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

class ClubPostView {
  const ClubPostView({
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
