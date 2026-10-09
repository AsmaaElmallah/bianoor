import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';

/// Shared pieces of the "clay" look used by the courses and live screens:
/// soft lifted cards, pill badges, a segmented control and the page header.

const double kClayRadiusLg = 32;
const double kClayRadiusXl = 48;

/// Mauve accent from the project palette, used where the design calls for a
/// warm secondary highlight (live CTAs, encouragement).
const Color kClayAccent = AppColors.trackVisualPurple;
const Color kClayAccentLight = AppColors.trackVisualLight;

BoxDecoration clayDecoration({
  Color color = Colors.white,
  double radius = kClayRadiusLg,
  double lift = 1,
  Gradient? gradient,
}) {
  return BoxDecoration(
    color: gradient == null ? color : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
    boxShadow: lift <= 0
        ? null
        : [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10 * lift),
              blurRadius: 28 * lift,
              offset: Offset(0, 10 * lift),
            ),
          ],
  );
}

class ClayHeader extends StatelessWidget implements PreferredSizeWidget {
  const ClayHeader({super.key, required this.title, this.saved, this.onToggleSave});

  final String title;
  final bool? saved;
  final VoidCallback? onToggleSave;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.92),
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _HeaderButton(
                icon: Symbols.arrow_back,
                square: true,
                color: AppColors.primary,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                ),
              ),
              if (saved != null) ...[
                _HeaderButton(
                  icon: Symbols.bookmark,
                  fill: saved! ? 1 : 0,
                  color: saved! ? AppColors.primary : AppColors.onSurfaceVariant,
                  background: AppColors.surfaceContainerLow,
                  onTap: onToggleSave,
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Symbols.person, size: 18, color: Colors.white, fill: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.square = false,
    this.fill = 0,
    this.background = Colors.white,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool square;
  final double fill;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final shape = square
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
        : const CircleBorder();
    return Material(
      color: background,
      shape: shape,
      elevation: square ? 3 : 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.35),
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: square ? 24 : 20, color: color, fill: fill),
        ),
      ),
    );
  }
}

class ClayPill extends StatelessWidget {
  const ClayPill({
    super.key,
    required this.text,
    this.icon,
    this.background = AppColors.primaryFixed,
    this.foreground = AppColors.onPrimaryFixedVariant,
    this.iconColor,
    this.leading,
    this.fontSize,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String text;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final Color? iconColor;
  final Widget? leading;
  final double? fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          if (icon != null) ...[
            Icon(icon, size: (fontSize ?? 13) + 3, color: iconColor ?? foreground, fill: 1),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: fontSize ?? 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pulsing dot used in "live" badges.
class ClayPulseDot extends StatefulWidget {
  const ClayPulseDot({super.key, this.color = AppColors.error, this.size = 10});

  final Color color;
  final double size;

  @override
  State<ClayPulseDot> createState() => _ClayPulseDotState();
}

class _ClayPulseDotState extends State<ClayPulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox.square(
      dimension: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + _c.value * 1.2,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.6 * (1 - _c.value)),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class ClaySegmented extends StatelessWidget {
  const ClaySegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                  decoration: i == selected
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: i == selected ? AppColors.primaryDim : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chunky pill button with a darker bottom edge, like a pressed clay block.
class ClayChunkyButton extends StatelessWidget {
  const ClayChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.edgeColor = AppColors.primaryDim,
    this.leadingIcon,
    this.trailingIcon,
    this.busy = false,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color edgeColor;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool busy;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: edgeColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: busy ? null : onPressed,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else if (leadingIcon != null)
                  Icon(leadingIcon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: fontSize),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 20, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section heading with the small vertical color bar.
class ClaySectionTitle extends StatelessWidget {
  const ClaySectionTitle({super.key, required this.title, this.barColor = AppColors.primary, this.trailing});

  final String title;
  final Color barColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 24,
            decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.onSurface),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
