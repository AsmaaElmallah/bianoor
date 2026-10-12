import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/community_cloud_repository.dart';

const _reportReasons = [
  'كلام مسيء أو تنمّر',
  'معلومة طبية غلط أو خطيرة',
  'إعلان أو سبام',
  'محتوى غير لائق',
  'سبب تاني',
];

/// Lets a mother flag a post or a reply for the admins.
Future<void> showClubReportSheet(BuildContext context, WidgetRef ref, {String? postId, String? commentId}) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              commentId != null ? 'الإبلاغ عن الرد' : 'الإبلاغ عن المنشور',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final r in _reportReasons)
            ListTile(
              leading: const Icon(Symbols.flag, color: AppColors.error),
              title: Text(r),
              onTap: () => Navigator.pop(ctx, r),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  try {
    await ref.read(communityCloudRepositoryProvider).report(postId: postId, commentId: commentId, reason: reason);
    if (context.mounted) showClubSnack(context, 'شكراً — البلاغ وصل لفريق بيانور وهيتراجع');
  } on ClubActionException catch (e) {
    if (context.mounted) showClubSnack(context, e.message);
  }
}

String clubTimeAgo(DateTime? at) {
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'دلوقتي';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  return '${at.day}/${at.month}/${at.year}';
}

void showClubSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
    ),
  );
}

BoxDecoration clubInsetDecoration() => BoxDecoration(
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
    );

class ClubField extends StatelessWidget {
  const ClubField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: clubInsetDecoration(),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            textAlign: TextAlign.right,
            validator: validator,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w500),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextField.hintStyle(theme),
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Post photo; tap opens it full screen with pinch-to-zoom.
class ClubPostImage extends StatelessWidget {
  const ClubPostImage({super.key, required this.url, this.height = 180});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (ctx) => GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(child: Center(child: Image.network(url))),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Image.network(
          url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  height: height,
                  color: AppColors.surfaceContainerLow,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
          errorBuilder: (_, __, ___) => Container(
            height: height,
            color: AppColors.surfaceContainerLow,
            alignment: Alignment.center,
            child: const Icon(Symbols.broken_image, color: AppColors.outline),
          ),
        ),
      ),
    );
  }
}

/// Small rounded label like «قيد المراجعة» on a post.
class ClubStatusPill extends StatelessWidget {
  const ClubStatusPill({super.key, required this.text, required this.background, required this.foreground, this.icon});

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.brFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: foreground),
          ),
        ],
      ),
    );
  }
}
