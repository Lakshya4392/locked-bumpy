import 'package:flutter/material.dart';

/// One-tap privacy control for screens that cover the nursery toolbar.
class PauseButton extends StatelessWidget {
  const PauseButton({super.key, required this.onPressed, required this.color});

  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Pause',
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: onPressed,
      icon: Icon(Icons.pause_circle_outline, color: color),
    );
  }
}
