import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';

/// Illustrated need icon inside a circular ring badge (inspired by clean health rings).
class NeedIconBadge extends StatelessWidget {
  const NeedIconBadge({
    super.key,
    required this.need,
    this.size = 46,
    this.isCompleted = false,
  });

  final MaternalNeed need;
  final double size;
  final bool isCompleted;

  static String iconPathFor(MaternalNeed need) {
    return switch (need) {
      MaternalNeed.iron => 'assets/images/needs/iron.png',
      MaternalNeed.brain => 'assets/images/needs/brain.png',
      MaternalNeed.bones => 'assets/images/needs/bones.png',
      MaternalNeed.water => 'assets/images/needs/water.png',
      MaternalNeed.rest => 'assets/images/needs/rest.png',
      MaternalNeed.vitamin => 'assets/images/needs/vitamin.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isCompleted
            ? need.color.withValues(alpha: 0.22)
            : palette.paperRaised,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? need.color : need.color.withValues(alpha: 0.35),
          width: isCompleted ? 2.5 : 1.5,
        ),
      ),
      child: Image.asset(
        iconPathFor(need),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Container(
          decoration: BoxDecoration(color: need.color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
