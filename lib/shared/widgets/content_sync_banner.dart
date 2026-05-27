import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/content/content_fetch_result.dart';
import '../../core/content/content_sync_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class ContentSyncBanner extends ConsumerWidget {
  const ContentSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(contentSyncProvider);

    return sync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        if (!state.showBanner) return const SizedBox.shrink();

        final (bg, icon, iconColor) = switch (state.severity) {
          ContentSyncSeverity.error => (
              AppColors.errorContainer,
              Symbols.cloud_off,
              AppColors.error,
            ),
          ContentSyncSeverity.warning => (
              AppColors.tertiaryContainer,
              Symbols.cloud_sync,
              AppColors.tertiary,
            ),
          ContentSyncSeverity.info => (
              AppColors.primaryContainer,
              Symbols.info,
              AppColors.primary,
            ),
          ContentSyncSeverity.ok => (
              AppColors.surfaceContainer,
              Symbols.cloud_done,
              AppColors.primary,
            ),
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: bg.withValues(alpha: 0.85),
            borderRadius: AppRadius.brLg,
            child: InkWell(
              borderRadius: AppRadius.brLg,
              onTap: () => ref.read(contentSyncProvider.notifier).refresh(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.bannerMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                              height: 1.35,
                            ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Symbols.refresh, size: 20),
                      color: iconColor,
                      onPressed: () =>
                          ref.read(contentSyncProvider.notifier).refresh(),
                      tooltip: 'إعادة المحاولة',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// رسالة قصيرة عند فتح قسم معيّن.
void showContentFetchSnackBar(
  BuildContext context,
  ContentFetchResult<dynamic> result,
  String featureLabel,
) {
  if (!result.shouldWarnUser) return;

  final isError = result.source == ContentFetchSource.errorFallback;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.userMessageAr(featureLabel)),
      backgroundColor: isError ? AppColors.error : AppColors.tertiary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ),
  );
}
