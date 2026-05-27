import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';

class MothersClubCategory {
  const MothersClubCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  static IconData iconFromKey(String key) {
    return switch (key) {
      'child_care' => Symbols.child_care,
      'menu_book' => Symbols.menu_book,
      'restaurant' => Symbols.restaurant,
      'toys' => Symbols.toys,
      _ => Symbols.groups,
    };
  }

  static (Color tint, Color iconColor) colorsForId(String id) {
    return switch (id) {
      'quran' => (AppColors.tertiaryFixed, AppColors.tertiary),
      'nutrition' => (AppColors.secondaryFixed, AppColors.secondary),
      'activities' => (AppColors.primaryContainer, AppColors.onPrimaryContainer),
      _ => (AppColors.primaryFixed, AppColors.primary),
    };
  }

  factory MothersClubCategory.fromMap(Map<String, dynamic> row) {
    final id = row['id'] as String? ?? 'general';
    final (tint, iconColor) = colorsForId(id);
    return MothersClubCategory(
      id: id,
      label: row['label'] as String? ?? id,
      icon: iconFromKey(row['icon_key'] as String? ?? ''),
      tint: tint,
      iconColor: iconColor,
    );
  }
}

class MothersClubPost {
  const MothersClubPost({
    required this.id,
    required this.authorDisplayName,
    required this.title,
    required this.body,
    required this.tag,
    required this.categoryId,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.likedByMe = false,
    this.muted = false,
    this.imageUrl,
  });

  final String id;
  final String authorDisplayName;
  final String title;
  final String body;
  final String tag;
  final String? categoryId;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool likedByMe;
  final bool muted;
  final String? imageUrl;

  String get timeAgoLabel => _formatTimeAgo(createdAt);

  (Color bg, Color fg) get tagColors {
    if (tag.contains('تغذية')) {
      return (AppColors.primaryFixed, AppColors.onPrimaryFixedVariant);
    }
    if (tag.contains('ختم')) {
      return (AppColors.secondaryContainer, AppColors.onSecondaryContainer);
    }
    return (AppColors.tertiaryContainer, AppColors.onTertiaryContainer);
  }

  MothersClubPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return MothersClubPost(
      id: id,
      authorDisplayName: authorDisplayName,
      title: title,
      body: body,
      tag: tag,
      categoryId: categoryId,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      likedByMe: likedByMe ?? this.likedByMe,
      muted: muted,
    );
  }

  factory MothersClubPost.fromMap(
    Map<String, dynamic> row, {
    bool likedByMe = false,
  }) {
    final tag = row['tag'] as String? ?? '';
    return MothersClubPost(
      id: row['id'] as String,
      authorDisplayName: row['author_display_name'] as String? ?? 'أم بيانور',
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      tag: tag,
      categoryId: row['category_id'] as String?,
      likeCount: row['like_count'] as int? ?? 0,
      commentCount: row['comment_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      likedByMe: likedByMe,
      muted: tag.contains('إعلان'),
      imageUrl: row['image_url'] as String?,
    );
  }
}

class MothersClubComment {
  const MothersClubComment({
    required this.id,
    required this.authorDisplayName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorDisplayName;
  final String body;
  final DateTime createdAt;

  String get timeAgoLabel => _formatTimeAgo(createdAt);

  factory MothersClubComment.fromMap(Map<String, dynamic> row) {
    return MothersClubComment(
      id: row['id'] as String,
      authorDisplayName: row['author_display_name'] as String? ?? 'أم بيانور',
      body: row['body'] as String? ?? '',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
