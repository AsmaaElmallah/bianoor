import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/visual_journey_stage.dart';

/// مسار عمودي (Stitch 3d_2tp).
class VisualJourneyPath extends StatelessWidget {
  const VisualJourneyPath({super.key, required this.curriculumDay});

  final int curriculumDay;

  static const _pathAccent = Color(0xFF8B7E3A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeIndex = visualActiveStageIndex(curriculumDay);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pathAccent,
            borderRadius: AppRadius.brLg,
            boxShadow: [
              BoxShadow(
                color: _pathAccent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'منهج التحفيز البصري',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'رحلة تطوير الإدراك البصري',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 24,
              bottom: 24,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.brFull,
                ),
              ),
            ),
            Column(
              children: [
                for (var i = 0; i < visualJourneyStages.length; i++) ...[
                  _JourneyNode(
                    stage: visualJourneyStages[i],
                    state: visualNodeStateForStage(i, activeIndex),
                    alignEnd: i.isOdd,
                    isLast: i == visualJourneyStages.length - 1,
                  ),
                  if (i < visualJourneyStages.length - 1) const SizedBox(height: 28),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.stage,
    required this.state,
    required this.alignEnd,
    required this.isLast,
  });

  final VisualJourneyStage stage;
  final VisualJourneyNodeState state;
  final bool alignEnd;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = state == VisualJourneyNodeState.completed;
    final active = state == VisualJourneyNodeState.active;
    final locked = state == VisualJourneyNodeState.locked;

    final nodeColor = completed || active
        ? VisualJourneyPath._pathAccent
        : AppColors.surfaceContainerHighest;
    final size = active ? 96.0 : 72.0;
    final icon = completed
        ? Symbols.check_circle
        : locked && isLast
            ? Symbols.visibility
            : Symbols.star;

    Widget node = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: nodeColor,
        shape: BoxShape.circle,
        border: active
            ? Border.all(color: AppColors.surfaceContainerLowest, width: 6)
            : null,
        boxShadow: active
            ? [
                BoxShadow(
                  color: VisualJourneyPath._pathAccent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: locked ? AppColors.outline : Colors.white,
        size: active ? 36 : 28,
        fill: locked ? 0 : 1,
      ),
    );

    if (active) {
      node = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          node,
          Positioned(
            top: -44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppRadius.brMd,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                stage.title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: VisualJourneyPath._pathAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Transform.translate(
      offset: Offset(alignEnd ? 36 : -36, 0),
      child: Column(
        children: [
          node,
          const SizedBox(height: 8),
          Text(
            stage.title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: locked ? AppColors.onSurfaceVariant : AppColors.onSurface,
            ),
          ),
          Text(
            stage.focusLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
