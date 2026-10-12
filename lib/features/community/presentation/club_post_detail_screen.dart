import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/app_logo_avatar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../library/domain/library_age_band.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../application/club_feed_provider.dart';
import '../data/community_cloud_repository.dart';
import 'widgets/club_shared.dart';

/// المنشور كامل + الردود + اللايك.
class ClubPostDetailScreen extends ConsumerStatefulWidget {
  const ClubPostDetailScreen({super.key, required this.post});

  final MothersClubPost post;

  @override
  ConsumerState<ClubPostDetailScreen> createState() => _ClubPostDetailScreenState();
}

class _ClubPostDetailScreenState extends ConsumerState<ClubPostDetailScreen> {
  final _reply = TextEditingController();
  bool _sending = false;

  MothersClubPost get post => widget.post;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.length < 2) return;
    setState(() => _sending = true);
    try {
      await ref.read(communityCloudRepositoryProvider).addComment(post.id, text);
      _reply.clear();
      if (mounted) FocusScope.of(context).unfocus();
      ref.invalidate(mothersClubCommentsProvider(post.id));
      ref.invalidate(mothersClubPostsProvider);
    } on ClubActionException catch (e) {
      if (mounted) showClubSnack(context, e.message);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر إرسال الرد، حاولي تاني');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleLike() async {
    try {
      await ref.read(mothersClubLikesProvider.notifier).toggle(post.id);
    } on ClubActionException catch (e) {
      if (mounted) showClubSnack(context, e.message);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر تسجيل الإعجاب');
    }
  }

  Future<void> _toggleSave() async {
    try {
      final saved = await ref.read(mothersClubSavesProvider.notifier).toggle(post.id);
      if (mounted) showClubSnack(context, saved ? 'اتحفظ — هتلاقيه في «المحفوظة» 🔖' : 'اتشال من المحفوظة');
    } on ClubActionException catch (e) {
      if (mounted) showClubSnack(context, e.message);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر الحفظ');
    }
  }

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لأ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('أيوه، احذفي')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deletePost() async {
    if (!await _confirm('تحذفي سؤالك؟')) return;
    try {
      await ref.read(communityCloudRepositoryProvider).deletePost(post.id);
      ref.invalidate(mothersClubPostsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر الحذف');
    }
  }

  Future<void> _deleteComment(MothersClubComment c) async {
    if (!await _confirm('تحذفي ردك؟')) return;
    try {
      await ref.read(communityCloudRepositoryProvider).deleteComment(c.id);
      ref.invalidate(mothersClubCommentsProvider(post.id));
      ref.invalidate(mothersClubPostsProvider);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر الحذف');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(communityCloudRepositoryProvider);
    final myId = repo.currentUserId;
    final isMine = myId != null && post.authorId == myId;
    ref.watch(mothersClubLikesProvider);
    final likes = ref.read(mothersClubLikesProvider.notifier);
    final liked = likes.isLiked(post.id);
    ref.watch(mothersClubSavesProvider);
    final saved = ref.read(mothersClubSavesProvider.notifier).isSaved(post.id);
    final comments = ref.watch(mothersClubCommentsProvider(post.id));
    final ageLabel = LibraryAgeBand.tryFromDb(post.categoryId)?.label;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: 'المناقشة', onBack: () => Navigator.of(context).pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(mothersClubCommentsProvider(post.id));
                      await ref.read(mothersClubCommentsProvider(post.id).future);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        TactileClayCard(
                          color: AppColors.surfaceContainerLowest,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  post.isAnonymous
                                      ? const CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.tertiaryContainer,
                                          child: Icon(Symbols.visibility_off, color: AppColors.onTertiaryContainer),
                                        )
                                      : const AppLogoAvatar(size: 44, imageAsset: AppAssets.logoBaby),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMine && post.isAnonymous ? '${post.displayAuthor} (إنتي)' : post.displayAuthor,
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                        Text(
                                          clubTimeAgo(post.createdAt),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(color: AppColors.outline, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (ageLabel != null)
                                    ClubStatusPill(
                                      text: ageLabel,
                                      background: AppColors.secondaryContainer,
                                      foreground: AppColors.onSecondaryContainer,
                                    ),
                                ],
                              ),
                              if (post.isPinned || post.hasExpertReply) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (post.isPinned)
                                      const ClubStatusPill(
                                        text: 'مثبّت من فريق بيانور',
                                        icon: Symbols.push_pin,
                                        background: AppColors.primaryFixed,
                                        foreground: AppColors.primary,
                                      ),
                                    if (post.hasExpertReply)
                                      const ClubStatusPill(
                                        text: 'ردّت الأخصائية',
                                        icon: Symbols.verified,
                                        background: Color(0xFFDDF2E3),
                                        foreground: Color(0xFF1E6B3A),
                                      ),
                                  ],
                                ),
                              ],
                              if (!post.isPublished) ...[
                                const SizedBox(height: 12),
                                post.isRejected
                                    ? const ClubStatusPill(
                                        text: 'السؤال ده ماتنشرش',
                                        icon: Symbols.block,
                                        background: AppColors.errorContainer,
                                        foreground: AppColors.onErrorContainer,
                                      )
                                    : const ClubStatusPill(
                                        text: 'قيد المراجعة — هيظهر للأمهات بعد الموافقة',
                                        icon: Symbols.hourglass_top,
                                        background: AppColors.tertiaryContainer,
                                        foreground: AppColors.onTertiaryContainer,
                                      ),
                              ],
                              const SizedBox(height: 14),
                              Text(post.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              SelectableText(
                                post.body,
                                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant, height: 1.6),
                              ),
                              if (post.imageUrl != null) ...[
                                const SizedBox(height: 12),
                                ClubPostImage(url: post.imageUrl!, height: 240),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  if (post.isPublished)
                                    InkWell(
                                      borderRadius: AppRadius.brFull,
                                      onTap: _toggleLike,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Symbols.favorite,
                                              size: 24,
                                              fill: liked ? 1 : 0,
                                              color: liked ? AppColors.error : AppColors.outline,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${likes.countFor(post)}',
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: liked ? AppColors.error : AppColors.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (post.isPublished)
                                    IconButton(
                                      tooltip: saved ? 'شيليه من المحفوظة' : 'احفظيه',
                                      onPressed: _toggleSave,
                                      icon: Icon(
                                        Symbols.bookmark,
                                        fill: saved ? 1 : 0,
                                        color: saved ? AppColors.primary : AppColors.outline,
                                      ),
                                    ),
                                  const Spacer(),
                                  if (isMine)
                                    TextButton.icon(
                                      onPressed: _deletePost,
                                      icon: const Icon(Symbols.delete, size: 18, color: AppColors.error),
                                      label: const Text('حذف سؤالي', style: TextStyle(color: AppColors.error)),
                                    )
                                  else if (post.isPublished)
                                    TextButton.icon(
                                      onPressed: () => showClubReportSheet(context, ref, postId: post.id),
                                      icon: const Icon(Symbols.flag, size: 18, color: AppColors.outline),
                                      label: const Text('إبلاغ', style: TextStyle(color: AppColors.outline)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          comments.maybeWhen(data: (c) => 'الردود (${c.length})', orElse: () => 'الردود'),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        comments.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (_, __) => const Text('تعذّر تحميل الردود'),
                          data: (list) {
                            if (list.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  post.isPublished ? 'لسه مفيش ردود — شاركي بتجربتك 💬' : 'الردود هتتفتح بعد نشر السؤال.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              );
                            }
                            return Column(
                              children: [
                                for (final c in list)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _CommentTile(
                                      comment: c,
                                      isMine: myId != null && c.authorId == myId,
                                      onDelete: () => _deleteComment(c),
                                      onReport: () => showClubReportSheet(context, ref, commentId: c.id),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (post.isPublished) _ReplyBar(controller: _reply, sending: _sending, onSend: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _expertBg = Color(0xFFEFF8F1);
const _expertFg = Color(0xFF1E6B3A);

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.isMine, required this.onDelete, required this.onReport});

  final MothersClubComment comment;
  final bool isMine;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expert = comment.isExpert;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expert ? _expertBg : AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: expert ? _expertFg.withValues(alpha: 0.45) : AppColors.outlineVariant.withValues(alpha: 0.5),
          width: expert ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                expert ? Symbols.verified : Symbols.account_circle,
                size: 22,
                color: expert ? _expertFg : AppColors.tertiary,
                fill: 1,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  expert
                      ? (comment.authorDisplayName?.isNotEmpty == true ? comment.authorDisplayName! : 'أخصائية بيانور')
                      : (comment.authorDisplayName?.isNotEmpty == true ? comment.authorDisplayName! : 'أم'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: expert ? _expertFg : null,
                  ),
                ),
              ),
              if (expert)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 6),
                  child: ClubStatusPill(text: 'رد الأخصائية', background: Colors.white, foreground: _expertFg),
                ),
              Text(
                clubTimeAgo(comment.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.outline, fontWeight: FontWeight.w700),
              ),
              if (isMine)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'حذف ردي',
                  onPressed: onDelete,
                  icon: const Icon(Symbols.delete, size: 18, color: AppColors.outline),
                )
              else if (!expert)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'إبلاغ',
                  onPressed: onReport,
                  icon: const Icon(Symbols.flag, size: 18, color: AppColors.outline),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(comment.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({required this.controller, required this.sending, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: clubInsetDecoration(),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 1500,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'اكتبي ردك…',
                  hintStyle: AppTextField.hintStyle(theme),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            icon: sending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : const Icon(Symbols.send, color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}
