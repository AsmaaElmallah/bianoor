import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/storage/prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../quran/domain/quran_age_schedule.dart';
import '../../application/premium_access.dart';
import '../../data/subscription_cloud_repository.dart';

/// Home banner shown when no lesson days are unlocked, or 5 or fewer are left.
class SubscribeBanner extends ConsumerStatefulWidget {
  const SubscribeBanner({super.key});

  @override
  ConsumerState<SubscribeBanner> createState() => _SubscribeBannerState();
}

class _SubscribeBannerState extends ConsumerState<SubscribeBanner> {
  bool _dismissed = false;

  /// Furthest curriculum day reached in any of the four lessons.
  int _furthestDay(PrefsService prefs) {
    return [
      prefs.getMathCurriculumDay(),
      prefs.getVisualCurriculumDay(),
      prefs.getEmotionalCurriculumDay(),
      quranCumulativeDay(prefs.getQuranKhatmahIndex(), prefs.getQuranSessionIndex()),
    ].reduce(math.max);
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    await ref
        .read(prefsServiceProvider)
        .setSubscribeBannerHiddenUntil(DateTime.now().add(const Duration(days: 3)));
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsServiceProvider);
    final access = ref.watch(lessonAccessProvider).valueOrNull;
    final hiddenUntil = prefs.getSubscribeBannerHiddenUntil();
    if (_dismissed ||
        access == null ||
        !access.known ||
        (hiddenUntil != null && hiddenUntil.isAfter(DateTime.now()))) {
      return const SizedBox.shrink();
    }

    final String title;
    final String body;
    if (access.days <= 0) {
      final plans = ref.watch(cloudSubscriptionPlansProvider).valueOrNull ?? const [];
      final monthly = plans.where((p) => p.canBuy && p.durationDays <= 31).firstOrNull;
      title = 'افتحي دروس طفلك';
      body = monthly == null
          ? 'القرآن والحساب والبصري والعاطفي — كل باقة بتفتح أيام بتفضل معاكِ على طول.'
          : 'أول شهر من الدروس الأربعة بـ ${monthly.price} بس، والأيام اللي بتتفتح بتفضل معاكِ على طول.';
    } else {
      final left = access.days - _furthestDay(prefs) + 1;
      if (left > 5) return const SizedBox.shrink();
      title = left <= 0 ? 'طفلك خلّص الأيام المفتوحة 👏' : 'فاضل $left يوم مفتوحين';
      body = 'افتحي الشهر الجاي عشان طفلك يكمل من غير ما يقف.';
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.secondaryContainer,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: () => openPlansForLessons(context, ref),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.lock_open,
                    color: AppColors.onSecondaryContainer,
                    fill: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSecondaryContainer.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  tooltip: 'إخفاء',
                  icon: const Icon(Symbols.close, size: 20),
                  color: AppColors.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
