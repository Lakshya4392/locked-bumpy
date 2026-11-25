import 'package:flutter/material.dart';

/// Smooth Apple-style staggered fade + upward slide entrance animation.
/// Uses [Interval] on a single controller (zero timers) and respects
/// [MediaQuery.disableAnimationsOf].
class StaggeredFadeSlide extends StatefulWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 440),
  });

  final Widget child;
  final int index;
  final Duration duration;

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    final start = (widget.index * 0.12).clamp(0.0, 0.55);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
