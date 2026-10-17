import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/arena_identity.dart';

enum ArenaPathNodeState { done, active, locked, upcoming }

class ArenaPathNodeData {
  const ArenaPathNodeData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.accent,
    this.icon = Symbols.star,
    this.characterAsset,
    this.speechBubble,
    this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final ArenaPathNodeState state;
  final Color accent;
  final IconData icon;
  /// BeBo / Arena mascot sitting on the node (Duolingo-style path).
  final String? characterAsset;
  final String? speechBubble;
  final VoidCallback? onTap;
}

/// Duolingo-style Arena path: green unit banner + dotted zigzag + character nodes.
class ArenaLearningPath extends StatelessWidget {
  const ArenaLearningPath({
    super.key,
    required this.unitTitle,
    required this.unitSubtitle,
    required this.progressLabel,
    required this.progressValue,
    required this.nodes,
    this.unitBadge = 'الوحدة الأولى',
  });

  final String unitBadge;
  final String unitTitle;
  final String unitSubtitle;
  final String progressLabel;
  final double progressValue;
  final List<ArenaPathNodeData> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UnitBanner(
          badge: unitBadge,
          title: unitTitle,
          subtitle: unitSubtitle,
          progressLabel: progressLabel,
          progressValue: progressValue,
        ),
        const SizedBox(height: 8),
        _ZigzagPath(nodes: nodes),
      ],
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    required this.progressValue,
  });

  final String badge;
  final String title;
  final String subtitle;
  final String progressLabel;
  final double progressValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipPath(
      clipper: _WavyBottomClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              ArenaIdentity.green,
              ArenaIdentity.green.withValues(alpha: 0.92),
              const Color(0xFF46A302),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressValue.clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progressLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavyBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 18);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 14);
    path.quadraticBezierTo(size.width * 0.75, size.height - 28, size.width, size.height - 12);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ZigzagPath extends StatelessWidget {
  const _ZigzagPath({required this.nodes});

  final List<ArenaPathNodeData> nodes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centerX = width / 2;
        const rowH = 148.0;
        final height = nodes.length * rowH + 36;

        return SizedBox(
          height: height,
          width: width,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _DottedPathPainter(
                  count: nodes.length,
                  rowH: rowH,
                  centerX: centerX,
                ),
              ),
              for (var i = 0; i < nodes.length; i++)
                Positioned(
                  top: 24 + i * rowH,
                  left: 0,
                  right: 0,
                  child: _PathRow(
                    node: nodes[i],
                    dx: ArenaIdentity.pathZigzag[i % ArenaIdentity.pathZigzag.length],
                    cardOnStart: i.isEven,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DottedPathPainter extends CustomPainter {
  _DottedPathPainter({
    required this.count,
    required this.rowH,
    required this.centerX,
  });

  final int count;
  final double rowH;
  final double centerX;

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final paint = Paint()
      ..color = ArenaIdentity.pathDot
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count - 1; i++) {
      final dx0 = ArenaIdentity.pathZigzag[i % ArenaIdentity.pathZigzag.length];
      final dx1 = ArenaIdentity.pathZigzag[(i + 1) % ArenaIdentity.pathZigzag.length];
      final y0 = 24 + i * rowH + 48;
      final y1 = 24 + (i + 1) * rowH + 48;
      final x0 = centerX + dx0;
      final x1 = centerX + dx1;
      final dist = math.sqrt(math.pow(x1 - x0, 2) + math.pow(y1 - y0, 2));
      final steps = (dist / 10).floor().clamp(4, 24);
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        final x = x0 + (x1 - x0) * t;
        final y = y0 + (y1 - y0) * t;
        canvas.drawCircle(Offset(x, y), 2.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPathPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.rowH != rowH;
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.node,
    required this.dx,
    required this.cardOnStart,
  });

  final ArenaPathNodeData node;
  final double dx;
  final bool cardOnStart;

  @override
  Widget build(BuildContext context) {
    final circle = _NodeCircle(node: node);
    final card = _NodeCard(node: node);

    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(dx, 0),
            child: circle,
          ),
          Positioned(
            left: cardOnStart ? 8 : null,
            right: cardOnStart ? null : 8,
            child: card,
          ),
        ],
      ),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  const _NodeCircle({required this.node});

  final ArenaPathNodeData node;

  @override
  Widget build(BuildContext context) {
    final done = node.state == ArenaPathNodeState.done;
    final active = node.state == ArenaPathNodeState.active;
    final locked = node.state == ArenaPathNodeState.locked;
    final size = active
        ? ArenaIdentity.nodeActive
        : done
            ? ArenaIdentity.nodeDone
            : ArenaIdentity.nodeLocked;

    final fill = locked
        ? ArenaIdentity.pathLocked
        : done
            ? node.accent
            : active
                ? node.accent
                : node.accent.withValues(alpha: 0.85);

    final character = node.characterAsset;
    final showCharacter = character != null && !locked;

    Widget core = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.35),
            blurRadius: active ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: showCharacter
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                character!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  node.icon,
                  color: Colors.white,
                  size: active ? 28 : 22,
                  fill: 1,
                ),
              ),
            )
          : Icon(
              locked
                  ? Symbols.lock
                  : done
                      ? Symbols.check
                      : node.icon,
              color: locked ? AppColors.primary.withValues(alpha: 0.55) : Colors.white,
              size: active ? 32 : 26,
              fill: 1,
              weight: 700,
            ),
    );

    if (active) {
      core = Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ArenaIdentity.activeRing, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: ArenaIdentity.activeRing.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: core,
      );
    }

    if (done) {
      core = Stack(
        clipBehavior: Clip.none,
        children: [
          core,
          Positioned(
            bottom: -2,
            left: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: ArenaIdentity.activeRing,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Symbols.check, size: 12, color: AppColors.onSurface, weight: 900),
            ),
          ),
        ],
      );
    }

    final bubble = node.speechBubble;
    return GestureDetector(
      onTap: node.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          core,
          if (bubble != null && bubble.isNotEmpty)
            Positioned(
              top: -36,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  bubble,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.node});

  final ArenaPathNodeData node;

  @override
  Widget build(BuildContext context) {
    final locked = node.state == ArenaPathNodeState.locked;
    final done = node.state == ArenaPathNodeState.done;
    final active = node.state == ArenaPathNodeState.active;
    final statusColor = done
        ? ArenaIdentity.green
        : active
            ? ArenaIdentity.orange
            : AppColors.onSurfaceVariant;

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: node.onTap,
        child: Container(
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: locked ? AppColors.onSurfaceVariant : AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                node.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
