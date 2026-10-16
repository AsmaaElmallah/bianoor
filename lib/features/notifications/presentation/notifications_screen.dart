import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/mascot_message.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../data/notifications_cloud_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sentNotificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'الإشعارات',
        onBack: () => context.pop(),
      ),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => MascotMessage.error(
                onAction: () => ref.invalidate(sentNotificationsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const MascotMessage(
                    title: 'مفيش إشعارات لسه',
                    message: 'أول ما ينزل جديد هيوصلك هنا.',
                    mascot: AppAssets.mascotEmpty,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(sentNotificationsProvider);
                    await ref.read(sentNotificationsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return TactileClayCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Symbols.notifications_active,
                              color: AppColors.tertiary,
                              fill: 1,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n.body,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.45,
                                    ),
                                  ),
                                  if (n.sentAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatDate(n.sentAt!),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }
}
