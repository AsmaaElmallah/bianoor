import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../growth/application/growth_providers.dart';
import '../../../growth/domain/growth_calc.dart';

/// Home row: growth + diaper color — one composition, two equal cards.
class HomeHealthToolsRow extends ConsumerWidget {
  const HomeHealthToolsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growth = ref.watch(growthDataProvider).valueOrNull;
    final child = growth?.child;
    final lastWeight = growth?.measurements.where((m) => m.weightKg != null).lastOrNull;
    final months = child?.birthDate != null ? ageInMonths(child!.birthDate!, DateTime.now()) : null;
    final ideal = child != null && months != null && child.isReady
        ? growthValueAtZ(GrowthMetric.weight, child.isMale, months, 0)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'صحة طفلك',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _HealthCard(
                    tint: AppColors.tertiaryContainer,
                    iconTint: AppColors.tertiary,
                    icon: Symbols.monitoring,
                    title: 'نموه',
                    body: lastWeight?.weightKg != null
                        ? 'آخر وزن ${lastWeight!.weightKg!.toStringAsFixed(1)} كجم'
                            '${months != null ? ' · ${months.round()} شهور' : ''}'
                        : ideal != null
                            ? 'الوزن المثالي حوالين ${ideal.toStringAsFixed(1)} كجم'
                            : 'سجّلي الوزن والطول على منحنى WHO',
                    progress: months == null ? null : (months / 24).clamp(0.0, 1.0),
                    onTap: () => context.push(AppRoutes.growth),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HealthCard(
                    tint: AppColors.secondaryContainer,
                    iconTint: AppColors.secondary,
                    icon: Symbols.baby_changing_station,
                    title: 'لون الحفاض',
                    body: 'اضغطي اللون الأقرب… واعرفي طبيعي ولا محتاج دكتور',
                    swatches: const [
                      Color(0xFFE3B505),
                      Color(0xFF6B8E23),
                      Color(0xFF8B5A2B),
                      Color(0xFFB22222),
                    ],
                    onTap: () => context.push(AppRoutes.stoolColors),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.tint,
    required this.iconTint,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.progress,
    this.swatches,
  });

  final Color tint;
  final Color iconTint;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final double? progress;
  final List<Color>? swatches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: tint,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: iconTint, fill: 1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 10),
              if (progress != null)
                ClipRRect(
                  borderRadius: AppRadius.brFull,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.55),
                    color: iconTint,
                  ),
                )
              else if (swatches != null)
                Row(
                  children: [
                    for (final c in swatches!)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
