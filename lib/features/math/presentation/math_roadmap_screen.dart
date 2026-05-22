import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';

/// Full curriculum timeline (Stitch 3d_2m).
class MathRoadmapScreen extends StatelessWidget {
  const MathRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(
        title: 'رحلة الرياضيات',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TactileClayCard(
            padding: const EdgeInsets.all(20),
            color: AppColors.primaryContainer.withValues(alpha: 0.35),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.brLg,
                  child: Image.asset(
                    AppAssets.mascotSpoonSitting,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Symbols.child_care,
                      size: 80,
                      color: AppColors.primary,
                      fill: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'رحلة الرياضيات',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'خارطة طريق تعليمية مخصصة لطفلك، تبدأ من المفاهيم الأساسية وتنمو مع نموه العقلي.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _RoadmapStage(
            badge: 'الأيام ١–٢٥',
            badgeColor: AppColors.secondaryContainer,
            onBadge: AppColors.onSecondaryContainer,
            icon: Symbols.lightbulb,
            iconColor: AppColors.secondary,
            title: 'البداية الذكية',
            stat: '٢',
            statUnit: 'يومياً',
            focus: 'التركيز: ٣–٨ ثوانٍ',
            body: 'التعريف بالأرقام والكميات البسيطة في بيئة هادئة.',
          ),
          const _RoadmapStage(
            badge: 'الأيام ٢٥–٤٢',
            badgeColor: AppColors.tertiaryContainer,
            onBadge: AppColors.onTertiaryContainer,
            icon: Symbols.auto_awesome,
            iconColor: AppColors.tertiary,
            title: 'توسيع المدارك',
            stat: '٣',
            statUnit: 'مرات',
            focus: 'التركيز: ٨–١٥ ثانية',
            body: 'زيادة التكرار لتعزيز الذاكرة البصرية والربط المنطقي.',
          ),
          const _RoadmapStage(
            badge: 'الأيام ٤٢–٦٠',
            badgeColor: AppColors.primaryContainer,
            onBadge: AppColors.onPrimaryContainer,
            icon: Symbols.rocket_launch,
            iconColor: AppColors.primary,
            title: 'مرحلة التكثيف',
            stat: '٤–٥',
            statUnit: 'مرات',
            focus: 'التركيز: ١٠–٣٠ ثانية',
            body: 'استيعاب كميات أكبر وتفاعلات رياضية أكثر تعقيداً.',
          ),
          const _RoadmapStage(
            badge: 'الشهر الثالث',
            badgeColor: AppColors.secondaryFixed,
            onBadge: AppColors.onSecondaryFixedVariant,
            icon: Symbols.calendar_month,
            iconColor: AppColors.secondary,
            title: 'ترسيخ المهارات',
            stat: '٥',
            statUnit: 'أيام / ٥ مرات',
            focus: 'التركيز: ١ – ١.٥ دقيقة',
            body: 'كل ٥ أيام خمس مرات يومياً لتثبيت المهارات.',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RoadmapMini(
                  icon: Symbols.child_care,
                  title: 'الأشهر ٤–٦',
                  body: 'تكرار كل ٣ أيام، ٥ مرات يومياً.',
                  chip: 'الحد الأقصى: ١ دقيقة',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoadmapMini(
                  icon: Symbols.psychology,
                  title: 'بعد الشهر ٦',
                  body: 'تبسيط المنطق، يوم نعم / يوم لا، جلسات حتى ٨ دقائق.',
                  chip: '٣ مرات يومياً',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoadmapStage extends StatelessWidget {
  const _RoadmapStage({
    required this.badge,
    required this.badgeColor,
    required this.onBadge,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.stat,
    required this.statUnit,
    required this.focus,
    required this.body,
  });

  final String badge;
  final Color badgeColor;
  final Color onBadge;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String stat;
  final String statUnit;
  final String focus;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TactileClayCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: AppRadius.brFull,
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: onBadge,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(icon, color: iconColor, fill: 1),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: AppRadius.brMd,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.05),
                        offset: const Offset(2, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        stat,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        statUnit,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(focus, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapMini extends StatelessWidget {
  const _RoadmapMini({
    required this.icon,
    required this.title,
    required this.body,
    required this.chip,
  });

  final IconData icon;
  final String title;
  final String body;
  final String chip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TactileClayCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22, fill: 1),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.brSm,
            ),
            child: Text(
              chip,
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
