import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/mothers_club_provider.dart';
import '../domain/mothers_club_models.dart';
import 'widgets/mothers_club_post_image.dart';

class MothersClubPostDetailScreen extends ConsumerStatefulWidget {
  const MothersClubPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<MothersClubPostDetailScreen> createState() =>
      _MothersClubPostDetailScreenState();
}

class _MothersClubPostDetailScreenState
    extends ConsumerState<MothersClubPostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;
  bool _liking = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(MothersClubPost post) async {
    final user = ref.read(authSessionProvider).valueOrNull?.user;
    if (user == null) {
      if (!mounted) return;
      context.push(AppRoutes.login);
      return;
    }

    setState(() => _liking = true);
    try {
      await ref.read(mothersClubRepositoryProvider).toggleLike(
            postId: post.id,
            userId: user.id,
            currentlyLiked: post.likedByMe,
          );
      ref.invalidate(mothersClubPostProvider(post.id));
      ref.invalidate(mothersClubFeedProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث الإعجاب: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _submitComment() async {
    final user = ref.read(authSessionProvider).valueOrNull?.user;
    if (user == null) {
      if (!mounted) return;
      context.push(AppRoutes.login);
      return;
    }

    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(mothersClubRepositoryProvider).addComment(
            postId: widget.postId,
            userId: user.id,
            authorDisplayName: user.name ?? user.email.split('@').first,
            body: body,
          );
      _commentController.clear();
      ref.invalidate(mothersClubCommentsProvider(widget.postId));
      ref.invalidate(mothersClubPostProvider(widget.postId));
      ref.invalidate(mothersClubFeedProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال التعليق: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(mothersClubPostProvider(widget.postId));
    final commentsAsync = ref.watch(mothersClubCommentsProvider(widget.postId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'المناقشة',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          postAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('تعذر التحميل: $e')),
            data: (post) {
              if (post == null) {
                return const Center(child: Text('المنشور غير موجود'));
              }

              final tagColors = post.tagColors;
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      children: [
                        TactileClayCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiaryContainer
                                          .withValues(alpha: 0.35),
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
                                  if (post.tag.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
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
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                MothersClubPostImage(imageUrl: post.imageUrl!, height: 200),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                post.body,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: _liking ? null : () => _toggleLike(post),
                                    borderRadius: AppRadius.brFull,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Symbols.favorite,
                                            size: 24,
                                            fill: post.likedByMe ? 1 : 0,
                                            color: post.likedByMe
                                                ? AppColors.error
                                                : AppColors.outline,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.likeCount}',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: post.likedByMe
                                                  ? AppColors.error
                                                  : AppColors.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  const Icon(
                                    Symbols.chat_bubble,
                                    size: 24,
                                    color: AppColors.outline,
                                  ),
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
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'التعليقات',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        commentsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text('تعذر تحميل التعليقات: $e'),
                          data: (comments) {
                            if (comments.isEmpty) {
                              return Text(
                                'لا تعليقات بعد — كوني أول من يشارك.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              );
                            }
                            return Column(
                              children: comments
                                  .map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _CommentTile(comment: c),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'اكتبي تعليقاً…',
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: AppRadius.brMd,
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TactileClayButton(
                            label: _sending ? '…' : 'إرسال',
                            icon: Symbols.send,
                            onPressed: _sending ? null : _submitComment,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final MothersClubComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TactileClayCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.authorDisplayName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                comment.timeAgoLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
