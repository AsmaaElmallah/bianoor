import 'package:flutter/material.dart';

import '../../../core/theme/arena_identity.dart';

/// Arena chatbot face — white line robot on purple FAB / tile.
class ArenaRobotIcon extends StatelessWidget {
  const ArenaRobotIcon({super.key, this.size = 28, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ArenaRobotPainter(color),
    );
  }
}

/// Arena purple FAB with online green dot.
class ArenaChatFab extends StatelessWidget {
  const ArenaChatFab({super.key, required this.onTap, this.size = ArenaIdentity.fabSize});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'اسألي بيانور',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ArenaIdentity.fabGradientTop, ArenaIdentity.fabGradientBottom],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ArenaIdentity.purple.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: ArenaRobotIcon(size: size * 0.48),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ArenaIdentity.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArenaRobotPainter extends CustomPainter {
  _ArenaRobotPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(5, 7, 14, 12),
      const Radius.circular(4),
    );
    canvas.drawRRect(head, p);
    canvas.drawLine(const Offset(12, 4), const Offset(12, 7), p);
    canvas.drawCircle(const Offset(12, 3.2), 1.2, Paint()..color = color);
    canvas.drawCircle(const Offset(9, 12), 1.15, Paint()..color = color);
    canvas.drawCircle(const Offset(15, 12), 1.15, Paint()..color = color);
    canvas.drawArc(
      const Rect.fromLTWH(9, 13.5, 6, 3.5),
      0.15,
      2.8,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _ArenaRobotPainter oldDelegate) => oldDelegate.color != color;
}
