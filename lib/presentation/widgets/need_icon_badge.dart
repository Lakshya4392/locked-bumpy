import 'package:flutter/material.dart';
import '../../domain/models/need.dart';

/// Illustrated need icon (clean, borderless PNG for high visual clarity).
class NeedIconBadge extends StatelessWidget {
  const NeedIconBadge({
    super.key,
    required this.need,
    this.size = 44,
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
    return AnimatedScale(
      scale: isCompleted ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          iconPathFor(need),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            decoration: BoxDecoration(
              color: need.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
