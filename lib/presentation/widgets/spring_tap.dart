import 'package:flutter/material.dart';

/// Tactile Apple-style spring press wrapper.
/// Scales down smoothly to [pressedScale] on pointer down and springs back on release.
/// Respects [MediaQuery.disableAnimationsOf].
class SpringTap extends StatefulWidget {
  const SpringTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.965,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations || widget.onTap == null) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
