import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// BeBo splash: full purple with a teal wave along the bottom edge.
class BeboSplashPurpleWave extends StatelessWidget {
  const BeboSplashPurpleWave({super.key, this.waveHeight = 148});

  final double waveHeight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.beboSplashPurple,
                AppColors.beboSplashPurpleDeep,
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: waveHeight,
          child: ClipPath(
            clipper: _BeboTopWaveClipper(),
            child: const ColoredBox(color: AppColors.beboTealWave),
          ),
        ),
      ],
    );
  }
}

/// Small doodles around the hero (flat icons / shapes, BeBo-like).
class BeboSplashSquiggles extends StatelessWidget {
  const BeboSplashSquiggles({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: MediaQuery.paddingOf(context).top + 56,
            left: 32,
            child: _Doodle(color: const Color(0xFFFFD54F), size: 28),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.28,
            left: 20,
            child: _Doodle(
              color: AppColors.secondary.withValues(alpha: 0.95),
              size: 22,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 72,
            right: 36,
            child: _Doodle(
              color: AppColors.beboTealWave.withValues(alpha: 0.9),
              size: 24,
            ),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.32,
            right: 28,
            child: _Doodle(
              color: AppColors.tertiary.withValues(alpha: 0.95),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _Doodle extends StatelessWidget {
  const _Doodle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BeboTopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, h * 0.42);
    path.quadraticBezierTo(w * 0.22, h * 0.08, w * 0.45, h * 0.28);
    path.quadraticBezierTo(w * 0.68, h * 0.48, w * 0.88, h * 0.18);
    path.quadraticBezierTo(w * 0.96, h * 0.08, w, h * 0.22);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BeboTopWaveClipper oldClipper) => false;
}
