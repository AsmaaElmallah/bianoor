import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';

/// Clay-style node on the khatmah / daily journey path.
class QuranJourneyNode extends StatelessWidget {
  const QuranJourneyNode({
    super.key,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isLocked,
    this.isBonus = false,
    this.subtitle,
    this.speechBubble,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final String? speechBubble;
  final bool isDone;
  final bool isActive;
  final bool isLocked;
  final bool isBonus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget circle;
    if (isDone) {
      circle = QuranJourneyClayCircle(
        size: 76,
        color: const Color(0xFF4ADE80),
        depth: const Color(0xFF16A34A),
        child: const Icon(Symbols.check_circle, color: Colors.white, size: 40, fill: 1),
      );
    } else if (isActive) {
      circle = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryContainer,
                width: 3,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
          QuranJourneyClayCircle(
            size: 80,
            color: AppColors.tertiary,
            depth: AppColors.tertiaryDim,
            onTap: onTap,
            child: const Icon(Symbols.play_arrow, color: Colors.white, size: 44, fill: 1),
          ),
          if (speechBubble != null)
            Positioned(
              top: -44,
              child: QuranJourneySpeechBubble(text: speechBubble!),
            ),
        ],
      );
    } else if (isBonus) {
      circle = QuranJourneyClayCircle(
        size: 88,
        color: AppColors.secondaryContainer,
        depth: AppColors.secondaryDim,
        child: Icon(
          isLocked ? Symbols.inventory_2 : Symbols.card_giftcard,
          color: AppColors.onSecondaryContainer,
          size: 36,
          fill: 1,
        ),
      );
    } else {
      circle = QuranJourneyClayCircle(
        size: 76,
        color: AppColors.surfaceContainerHigh,
        depth: AppColors.outlineVariant,
        child: Icon(
          isLocked ? Symbols.lock : Symbols.star,
          color: AppColors.outline,
          size: 34,
        ),
      );
    }

    return Column(
      children: [
        circle,
        const SizedBox(height: 10),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class QuranJourneyClayCircle extends StatefulWidget {
  const QuranJourneyClayCircle({
    super.key,
    required this.size,
    required this.color,
    required this.depth,
    required this.child,
    this.onTap,
  });

  final double size;
  final Color color;
  final Color depth;
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<QuranJourneyClayCircle> createState() => _QuranJourneyClayCircleState();
}

class _QuranJourneyClayCircleState extends State<QuranJourneyClayCircle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: widget.depth, offset: Offset(0, _pressed ? 2 : 6)),
            ...AppShadows.soft,
          ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class QuranJourneySpeechBubble extends StatelessWidget {
  const QuranJourneySpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer, width: 2),
        boxShadow: AppShadows.soft,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

/// Zig-zag horizontal offsets for path nodes.
const quranJourneyPathOffsets = [48.0, 0.0, -48.0, 0.0, 32.0];
