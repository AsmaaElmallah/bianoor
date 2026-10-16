import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/arena_identity.dart';

/// Arena marketing-style feature hero used above track journeys.
class ArenaFeatureHero extends StatelessWidget {
  const ArenaFeatureHero({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.background,
    this.badge,
    this.tags = const [],
    this.child,
    this.iconWellColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color background;
  final String? badge;
  final List<String> tags;
  final Widget? child;
  final Color? iconWellColor;

  bool get _dark => background.computeLuminance() < 0.45;

  @override
  Widget build(BuildContext context) {
    final on = _dark ? Colors.white : AppColors.onSurface;
    final onMuted = _dark ? Colors.white.withValues(alpha: 0.9) : AppColors.onSurfaceVariant;
    final well = iconWellColor ?? (_dark ? Colors.white.withValues(alpha: 0.18) : AppColors.primary);

    final usePurpleGradient = background == AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: usePurpleGradient ? null : background,
        gradient: usePurpleGradient ? AppColors.todayPlanGradient : null,
        borderRadius: BorderRadius.circular(28),
        border: background == Colors.white
            ? Border.all(color: AppColors.outlineVariant)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _dark
                              ? Colors.white.withValues(alpha: 0.16)
                              : ArenaIdentity.orange.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: _dark ? Colors.white : ArenaIdentity.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: on,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: onMuted,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: well,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 26, fill: 1),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _dark
                          ? Colors.white.withValues(alpha: 0.14)
                          : const Color(0xFFFFF0E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        color: _dark ? Colors.white : AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Mini Quran player strip matching Arena purple card.
class ArenaMiniPlayerStrip extends StatelessWidget {
  const ArenaMiniPlayerStrip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.progress,
    this.onPlay,
  });

  final String title;
  final String subtitle;
  final String progressLabel;
  final double progress;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlay,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Symbols.play_arrow, color: AppColors.primary, fill: 1, size: 28),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                progressLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: ArenaIdentity.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// High-contrast preview tiles for visual track (Arena).
class ArenaContrastTiles extends StatelessWidget {
  const ArenaContrastTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tile(Icons.sentiment_satisfied_alt_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _tile(null, checker: true)),
        const SizedBox(width: 8),
        Expanded(child: _tile(Icons.radio_button_checked)),
      ],
    );
  }

  Widget _tile(IconData? icon, {bool checker = false}) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: checker
            ? CustomPaint(painter: _CheckerPainter())
            : Icon(icon, color: Colors.black, size: 36),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = Colors.black;
    final white = Paint()..color = Colors.white;
    const n = 3;
    final w = size.width / n;
    final h = size.height / n;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * w, r * h, w + 0.5, h + 0.5),
          ((r + c).isEven) ? black : white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
