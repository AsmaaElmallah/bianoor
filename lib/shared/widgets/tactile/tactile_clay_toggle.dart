import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Clay-style نعم / لا toggle (mahara tactile assessment).
class TactileClayToggle extends StatelessWidget {
  const TactileClayToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ClayToggleChip(
            label: 'نعم',
            isSelected: value == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ClayToggleChip(
            label: 'لا',
            isSelected: value == false,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _ClayToggleChip extends StatefulWidget {
  const _ClayToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ClayToggleChip> createState() => _ClayToggleChipState();
}

class _ClayToggleChipState extends State<_ClayToggleChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerLow,
            borderRadius: AppRadius.brFull,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.8),
              width: widget.isSelected ? 2 : 3,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.08),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: -1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.05),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: widget.isSelected
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
