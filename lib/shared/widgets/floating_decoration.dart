import 'package:flutter/material.dart';

/// Continuously bobs up and down. Used for ambient decoration icons.
class FloatingDecoration extends StatefulWidget {
  const FloatingDecoration({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 6),
    this.amplitude = 16,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final double amplitude;
  final Duration delay;

  @override
  State<FloatingDecoration> createState() => _FloatingDecorationState();
}

class _FloatingDecorationState extends State<FloatingDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -widget.amplitude * _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
