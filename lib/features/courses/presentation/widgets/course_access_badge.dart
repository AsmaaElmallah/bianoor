import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/course.dart';

class CourseAccessBadge extends StatelessWidget {
  const CourseAccessBadge({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (course.accessType) {
      CourseAccessType.free => (AppColors.tertiaryContainer, AppColors.tertiary, Symbols.lock_open),
      CourseAccessType.subscription => (AppColors.primaryContainer, AppColors.primaryDim, Symbols.workspace_premium),
      CourseAccessType.paid => (AppColors.secondaryContainer, AppColors.secondary, Symbols.sell),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            course.accessLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class CourseCover extends StatelessWidget {
  const CourseCover({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.primaryContainer,
      alignment: Alignment.center,
      child: const Icon(Symbols.school, size: 48, color: AppColors.primary),
    );
    final src = url;
    if (src == null || src.isEmpty) return placeholder;
    return Image.network(
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
    );
  }
}
