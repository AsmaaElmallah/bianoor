import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../../quran/presentation/widgets/tactile/tactile_clay_card.dart';
import '../domain/emotional_curriculum_schedule.dart';
import '../domain/emotional_journey_stage.dart';

/// خارطة منهج الذكاء الاجتماعي/العاطفي (Stitch 3d_1zeg).
class EmotionalRoadmapScreen extends StatelessWidget {
  const EmotionalRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8D4DC),
      appBar: QuranTactileAppBar(
        title: 'خطة الذكاء الاجتماعي والعاطفي',
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TactileClayCard(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFE8A0B0).withValues(alpha: 0.25),
            child: Column(
              children: [
                const Icon(Symbols.favorite, size: 56, color: Color(0xFFE8A0B0), fill: 1),
                const SizedBox(height: 12),
                Text(
                  'منهج الذكاء الاجتماعي والعاطفي',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$emotionalLessonCount درساً · $emotionalExpectedGlobalSlideCount شريحة · ينتهي المحتوى الجديد يوم $emotionalLastNewContentDay',
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
          const _PhaseCard(
            number: '١',
            title: 'المرحلة الأولى: التأسيس',
            days: '١–٢٥ يوم',
            reps: 'مرتين يومياً',
            focus: '٣–٨ ثوانٍ',
            slides: '٥ شرائح',
          ),
          const _PhaseCard(
            number: '٢',
            title: 'المرحلة الثانية: التوسع',
            days: '٢٦–٤٢ يوم',
            reps: '٣ مرات يومياً',
            focus: '٨–١٥ ثانية',
            slides: '١٠ شرائح',
          ),
          const _PhaseCard(
            number: '٣',
            title: 'مرحلة التكثيف',
            days: '٤٣–٥٠ يوم',
            reps: '٤ مرات يومياً',
            focus: '١٠–٣٠ ثانية',
            slides: '١٠ شرائح',
          ),
          const _PhaseCard(
            number: '٤',
            title: 'ترسيخ المهارات',
            days: '٥١–٥٥ يوم',
            reps: '٥ مرات يومياً',
            focus: '١٠–٣٠ ثانية',
            slides: '١٠ شرائح',
          ),
          const _PhaseCard(
            number: '٥+',
            title: 'دروس ٥–١٧',
            days: '٥٦–$emotionalLastNewContentDay (٥ أيام/درس)',
            reps: '٥ مرات يومياً',
            focus: '١–١.٥ دقيقة ثم ١ دقيقة',
            slides: '١٠ شرائح (الدرس ١٧ = ٧)',
            highlight: true,
          ),
          const SizedBox(height: 12),
          ...emotionalJourneyStages.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TactileClayCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            s.focusLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      s.dayEnd >= 9999
                          ? 'من يوم $emotionalReviewCycleStartDay'
                          : 'حتى يوم ${s.dayEnd}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.number,
    required this.title,
    required this.days,
    required this.reps,
    required this.focus,
    required this.slides,
    this.highlight = false,
  });

  final String number;
  final String title;
  final String days;
  final String reps;
  final String focus;
  final String slides;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TactileClayCard(
        padding: const EdgeInsets.all(16),
        color: highlight
            ? AppColors.primaryContainer.withValues(alpha: 0.25)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE8A0B0).withValues(alpha: 0.35),
                borderRadius: AppRadius.brMd,
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Chip(days),
                  const SizedBox(height: 4),
                  _Chip(reps),
                  const SizedBox(height: 4),
                  _Chip(focus),
                  const SizedBox(height: 4),
                  _Chip(slides),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}
