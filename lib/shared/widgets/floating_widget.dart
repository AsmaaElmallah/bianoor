import 'package:flutter/material.dart';

/// Gentle vertical float animation — wraps any child and makes it float up/down.
/// Matches the `@keyframes floating` 6s from the Bianur/Lullaby HTML designs.
class FloatingWidget extends StatefulWidget {
  const FloatingWidget({
    super.key,
    required this.child,
    this.amplitude = 10.0,
    this.duration = const Duration(seconds: 4),
    this.curve = Curves.easeInOut,
  });

  final Widget child;

  /// How many pixels up/down (default 10)
  final double amplitude;

  /// Full cycle duration (default 4s — slightly faster than HTML 6s for more life)
  final Duration duration;

  final Curve curve;

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _offset = Tween<double>(
      begin: -widget.amplitude,
      end: widget.amplitude,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _offset.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}
