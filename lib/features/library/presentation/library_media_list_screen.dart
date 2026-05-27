import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/content/content_providers.dart';
import '../../../shared/widgets/content_sync_banner.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../domain/library_media_catalog.dart';

/// قائمة مقاطع YouTube لفئة (طبيعة / موسيقى / تهويدات).
class LibraryMediaListScreen extends ConsumerStatefulWidget {
  const LibraryMediaListScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<LibraryMediaListScreen> createState() => _LibraryMediaListScreenState();
}

class _LibraryMediaListScreenState extends ConsumerState<LibraryMediaListScreen> {
  bool _snackShown = false;

  @override
  Widget build(BuildContext context) {
    final asyncCategory = ref.watch(libraryCategoryProvider(widget.categoryId));

    return asyncCategory.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: QuranTactileAppBar(title: 'المحتوى', onBack: () => context.pop()),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _fallbackScaffold(context, ref),
      data: (category) {
        if (!_snackShown) {
          _snackShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final result =
                await ref.read(libraryRepositoryProvider).loadCategoriesResult();
            if (!mounted) return;
            showContentFetchSnackBar(context, result, 'المكتبة');
          });
        }
        if (category == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: QuranTactileAppBar(title: 'المحتوى', onBack: () => context.pop()),
            body: const Center(child: Text('المحتوى غير متوفر')),
          );
        }
        return _ListBody(category: category, categoryId: widget.categoryId);
      },
    );
  }

  Widget _fallbackScaffold(BuildContext context, WidgetRef ref) {
    final category = libraryCategoryByMenuId(widget.categoryId);
    if (category == null) {
      return Scaffold(
        appBar: QuranTactileAppBar(title: 'المحتوى', onBack: () => context.pop()),
        body: const Center(child: Text('المحتوى غير متوفر')),
      );
    }
    return _ListBody(category: category, categoryId: widget.categoryId);
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.category, required this.categoryId});

  final LibraryMediaCategory category;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: category.title,
        onBack: () => context.pop(),
      ),
      body: ListView.separated(
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
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Symbols.play_circle, color: AppColors.primary),
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
                      if (item.durationLabel != null)
                        Text(
                          item.durationLabel!,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
