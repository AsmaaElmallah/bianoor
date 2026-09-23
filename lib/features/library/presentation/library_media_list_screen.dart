import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../data/library_content_repository.dart';
import '../domain/library_media_catalog.dart';

/// قائمة مقاطع YouTube لفئة (طبيعة / موسيقى / تهويدات).
class LibraryMediaListScreen extends ConsumerWidget {
  const LibraryMediaListScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncCategory = ref.watch(libraryCategoryProvider(categoryId));

    return asyncCategory.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: QuranTactileAppBar(title: 'المحتوى', onBack: () => context.pop()),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: QuranTactileAppBar(title: 'المحتوى', onBack: () => context.pop()),
        body: const Center(child: Text('تعذّر تحميل المحتوى من السحابة')),
      ),
      data: (category) => _buildBody(context, ref, theme, category),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    LibraryMediaCategory? category,
  ) {
    if (category == null) {
      return Scaffold(
        appBar: QuranTactileAppBar(title: 'المحتوى', onBack: () => context.pop()),
        body: const Center(child: Text('المحتوى غير متوفر')),
      );
    }

    if (category.items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: QuranTactileAppBar(
          title: category.title,
          onBack: () => context.pop(),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'لا يوجد محتوى منشور من الإدارة بعد.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: category.title,
        onBack: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(libraryCategoryProvider(categoryId));
          await ref.read(libraryCategoryProvider(categoryId).future);
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          itemCount: category.items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return TactileClayCard(
                color: AppColors.primaryContainer.withValues(alpha: 0.35),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(category.icon, color: AppColors.primary, size: 32, fill: 1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${category.items.length} مقطع — اضغطي للتشغيل',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final item = category.items[index - 1];
            return TactileClayCard(
              onTap: () => context.push(
                AppRoutes.libraryMediaWatchPath(
                  categoryId,
                  videoId: item.videoId,
                  playlistId: item.playlistId,
                  title: item.title,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.isPlaylist ? Symbols.playlist_play : Symbols.play_arrow,
                      color: AppColors.secondary,
                      fill: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (item.moodTag != null)
                          Text(
                            item.moodTag!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.durationLabel != null)
                    Text(
                      item.durationLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
