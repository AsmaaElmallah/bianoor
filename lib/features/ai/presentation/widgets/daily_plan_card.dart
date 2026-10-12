import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/supabase/supabase_bootstrap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/ai_providers.dart';
import '../../data/ai_models.dart';

/// Home card: today's smart plan + entry to «مساعدة بيانور».
class DailyPlanCard extends ConsumerWidget {
  const DailyPlanCard({super.key, required this.babyName});

  final String babyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseBootstrap.isEnabled) return const SizedBox.shrink();
    final settings = ref.watch(aiSettingsProvider).valueOrNull;
    if (settings != null && !settings.enabled) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final plan = ref.watch(aiDailyPlanProvider);
    final result = plan.valueOrNull;

    String subtitle;
    if (plan.isLoading) {
      subtitle = 'بنجهزلك أنشطة النهارده…';
    } else if (result?.plan != null && result!.plan!.activities.isNotEmpty) {
      final first = withBabyName(result.plan!.activities.first.title, babyName);
      final more = result.plan!.activities.length - 1;
      subtitle = more > 0 ? '$first و$more أنشطة كمان' : first;
    } else {
      subtitle = 'دوسي عشان نجهز خطة النهارده';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.brXl,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              borderRadius: AppRadius.brXl,
              onTap: () {
                if (result?.plan == null && !plan.isLoading) ref.invalidate(aiDailyPlanProvider);
                context.push(AppRoutes.dailyPlan);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceContainerLowest,
                      child: Icon(Symbols.auto_awesome, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خطة النهارده لـ $babyName',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.aiAssistant),
                      icon: const Icon(Symbols.chat, size: 20),
                      label: const Text('اسألي مساعدة بيانور'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(AppRoutes.growth),
                    icon: const Icon(Symbols.monitoring, size: 20),
                    label: const Text('نموه'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLowest,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
