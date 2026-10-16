import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Colors copied from the Bayanour landing chat widget.
abstract final class AiSiteColors {
  static const ink950 = Color(0xFF04161A);
  static const ink900 = Color(0xFF07282C);
  static const ink800 = Color(0xFF0B3A3C);
  static const headerTop = Color(0xFF10524C);
  static const sendTop = Color(0xFF146B60);
  static const teal = Color(0xFF0E8F86);
  static const mint300 = Color(0xFF7EDCC6);
  static const mint200 = Color(0xFFB9EDE1);
  static const honey = Color(0xFFF7C550);
  static const apricot = Color(0xFFFF8A5C);
  static const cream50 = Color(0xFFFFFCF6);
  static const cream100 = Color(0xFFFBF4E7);

  static const ease = Cubic(0.22, 1, 0.36, 1);

  static const headerGradient = LinearGradient(
    begin: Alignment(-0.5, -0.87),
    end: Alignment(0.5, 0.87),
    colors: [headerTop, ink900],
  );

  static const innerOrbGradient = LinearGradient(
    begin: Alignment(-0.5, -0.87),
    end: Alignment(0.5, 0.87),
    colors: [ink800, ink950],
  );

  static const messageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream100, cream50],
  );

  static const sendGradient = LinearGradient(
    begin: Alignment(-0.71, -0.71),
    end: Alignment(0.71, 0.71),
    colors: [sendTop, ink800],
  );
}

/// The landing-page face: blinking eyes, pulsing star, speech-bubble body.
class BayanourFace extends StatefulWidget {
  const BayanourFace({super.key, this.size = 32});

  final double size;

  @override
  State<BayanourFace> createState() => _BayanourFaceState();
}

class _BayanourFaceState extends State<BayanourFace> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) setState(() => _elapsed = elapsed);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double get _seconds => _elapsed.inMicroseconds / 1000000;

  /// Landing `blink`: 4.2s ease-in-out, second eye delayed 0.12s.
  double _blink(double delay) {
    final period = 4.2;
    var p = ((_seconds - delay) % period) / period;
    if (p < 0) p += 1;
    final dist = (p - 0.5).abs() * 2;
    final eased = Curves.easeInOut.transform(dist);
    return 0.15 + 0.85 * eased;
  }

  /// Landing `pulse-soft`: 3s, scale 1 → 1.2 and opacity 0.95 → 0.5.
  double get _starT {
    final p = (_seconds % 3) / 3;
    return Curves.easeInOut.transform(p < 0.5 ? p * 2 : (1 - p) * 2);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _FacePainter(
        eyeLeft: _blink(0),
        eyeRight: _blink(0.12),
        star: _starT,
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  const _FacePainter({required this.eyeLeft, required this.eyeRight, required this.star});

  final double eyeLeft;
  final double eyeRight;
  final double star;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    canvas.save();
    canvas.scale(s);

    final body = Path()
      ..moveTo(20, 4.5)
      ..cubicTo(28.56, 4.5, 35.5, 10.1, 35.5, 17)
      ..cubicTo(35.5, 23.9, 28.56, 29.5, 20, 29.5)
      ..cubicTo(18.5, 29.5, 17.05, 29.33, 15.7, 29.02)
      ..lineTo(8.1, 32.6)
      ..arcToPoint(const Offset(6.55, 31.3), radius: const Radius.circular(1.1), clockwise: true)
      ..relativeLineTo(1.2, -5.5)
      ..arcToPoint(const Offset(4.5, 17), radius: const Radius.circular(11.7), clockwise: true)
      ..cubicTo(4.5, 10.1, 11.44, 4.5, 20, 4.5)
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.7, -0.7),
        end: Alignment(0.7, 0.7),
        colors: [AiSiteColors.mint200, AiSiteColors.mint300],
      ).createShader(const Rect.fromLTWH(6, 6, 28, 28));
    canvas.drawPath(body, fill);
    canvas.drawShadow(body, const Color(0x80000000), 3, false);
    canvas.drawPath(body, fill);

    final eye = Paint()..color = AiSiteColors.ink950;
    canvas.drawOval(Rect.fromCenter(center: const Offset(15.4, 16.2), width: 3.4, height: 4.4), eye..color = AiSiteColors.ink950.withValues(alpha: eyeLeft));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(24.6, 16.2), width: 3.4, height: 4.4),
      Paint()..color = AiSiteColors.ink950.withValues(alpha: eyeRight),
    );

    final smile = Path()
      ..moveTo(16.4, 22.2)
      ..cubicTo(18.6, 23.7, 21.4, 23.7, 23.6, 22.2);
    canvas.drawPath(
      smile,
      Paint()
        ..color = AiSiteColors.ink950
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.9
        ..strokeCap = StrokeCap.round,
    );

    canvas.save();
    canvas.translate(32.6, 7.9);
    canvas.scale(1 + 0.2 * star);
    canvas.translate(-32.6, -7.9);
    final spark = Path()
      ..moveTo(32.6, 4.2)
      ..relativeLineTo(1, 2.7)
      ..relativeLineTo(2.7, 1)
      ..relativeLineTo(-2.7, 1)
      ..relativeLineTo(-1, 2.7)
      ..relativeLineTo(-1, -2.7)
      ..relativeLineTo(-2.7, -1)
      ..relativeLineTo(2.7, -1)
      ..close();
    canvas.drawPath(spark, Paint()..color = AiSiteColors.honey.withValues(alpha: 0.95 - 0.45 * star));
    canvas.restore();

    canvas.drawCircle(const Offset(7, 33), 2.2, Paint()..color = AiSiteColors.apricot.withValues(alpha: 0.9));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) =>
      oldDelegate.eyeLeft != eyeLeft || oldDelegate.eyeRight != eyeRight || oldDelegate.star != star;
}

/// Closed launcher: spinning ring, pulse, orbiting dot, face and badge.
class AiLauncherPill extends StatefulWidget {
  const AiLauncherPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AiLauncherPill> createState() => _AiLauncherPillState();
}

class _AiLauncherPillState extends State<AiLauncherPill> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) setState(() => _elapsed = elapsed);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double get _seconds => _elapsed.inMicroseconds / 1000000;

  @override
  Widget build(BuildContext context) {
    final spin = (_seconds % 34) / 34 * math.pi * 2;
    final orbit = (_seconds % 6.5) / 6.5 * math.pi * 2;
    final pulse = _pulse((_seconds % 2.6) / 2.6);

    return Semantics(
      button: true,
      label: 'افتحي مساعدة بيانور',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xF204161A), blurRadius: 22, offset: Offset(0, 10)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Transform.rotate(
                    angle: spin,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          startAngle: 110 * math.pi / 180,
                          colors: [
                            AiSiteColors.mint300,
                            AiSiteColors.honey,
                            AiSiteColors.apricot,
                            AiSiteColors.mint300,
                          ],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: AiSiteColors.innerOrbGradient),
                      child: SizedBox.expand(),
                    ),
                  ),
                  Transform.scale(
                    scale: pulse.scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AiSiteColors.mint300.withValues(alpha: 0.4 * pulse.opacity)),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Transform.rotate(
                    angle: orbit,
                    child: Transform.translate(
                      offset: const Offset(24, 0),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AiSiteColors.honey,
                          boxShadow: [
                            BoxShadow(color: AiSiteColors.honey.withValues(alpha: 0.8), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const BayanourFace(size: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _Pulse _pulse(double t) {
    if (t >= 0.7) return const _Pulse(scale: 1.6, opacity: 0);
    final local = AiSiteColors.ease.transform(t / 0.7);
    return _Pulse(scale: 0.85 + 0.75 * local, opacity: 0.7 * (1 - local));
  }
}

class _Pulse {
  const _Pulse({required this.scale, required this.opacity});
  final double scale;
  final double opacity;
}

/// Open state of the same pill: ring with a close mark and «إغلاق المحادثة».
class AiClosePill extends StatelessWidget {
  const AiClosePill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'إغلاق المحادثة',
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AiSiteColors.ink950.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AiSiteColors.cream100.withValues(alpha: 0.12)),
            boxShadow: const [
              BoxShadow(color: Color(0xF204161A), blurRadius: 60, spreadRadius: -24, offset: Offset(0, 28)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AiSiteColors.innerOrbGradient),
                  foregroundDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AiSiteColors.mint300.withValues(alpha: 0.35), width: 3),
                  ),
                  child: CustomPaint(size: const Size.square(20), painter: _CloseMarkPainter()),
                ),
                const SizedBox(width: 12),
                Text(
                  'إغلاق المحادثة',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AiSiteColors.cream50,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AiSiteColors.cream50
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final s = size.width / 24;
    canvas.scale(s);
    canvas.drawLine(const Offset(6.4, 6.4), const Offset(17.6, 17.6), paint);
    canvas.drawLine(const Offset(17.6, 6.4), const Offset(6.4, 17.6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Four-point sparkle used on the landing send button.
class AiSparkleIcon extends StatelessWidget {
  const AiSparkleIcon({super.key, this.size = 16, this.color = AiSiteColors.mint300});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _SparklePainter(color));
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final paint = Paint()..color = color;
    final big = Path()
      ..moveTo(11, 1.8)
      ..relativeLineTo(2, 5.7)
      ..relativeLineTo(5.7, 2)
      ..relativeLineTo(-5.7, 2)
      ..relativeLineTo(-2, 5.7)
      ..relativeLineTo(-2, -5.7)
      ..relativeLineTo(-5.7, -2)
      ..relativeLineTo(5.7, -2)
      ..close();
    final small = Path()
      ..moveTo(18.6, 14.4)
      ..relativeLineTo(1, 2.6)
      ..relativeLineTo(2.6, 1)
      ..relativeLineTo(-2.6, 1)
      ..relativeLineTo(-1, 2.6)
      ..relativeLineTo(-1, -2.6)
      ..relativeLineTo(-2.6, -1)
      ..relativeLineTo(2.6, -1)
      ..close();
    canvas.drawPath(big, paint);
    canvas.drawPath(small, Paint()..color = color.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => oldDelegate.color != color;
}
