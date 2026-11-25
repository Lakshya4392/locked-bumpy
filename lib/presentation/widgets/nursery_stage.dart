import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';
import 'baby_avatar.dart';

/// Illustrated nursery backdrop + 5-layer [BabyAvatar] stage card.
class NurseryStage extends StatelessWidget {
  const NurseryStage({
    super.key,
    required this.need,
    this.tone = AppConstants.defaultBabyTone,
    this.expression = 'calm',
    this.poseOverride,
    this.height = 205,
    this.avatarSize = 154,
    this.hopAnimation,
    this.topLeftBadge,
    this.showSparkle = false,
  });

  final MaternalNeed need;
  final String tone;
  final String expression;
  final String? poseOverride;
  final double height;
  final double avatarSize;
  final Animation<double>? hopAnimation;
  final Widget? topLeftBadge;
  final bool showSparkle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final stageAsset = palette.isHalloween
        ? 'assets/images/stage/night-nursery-violet.png'
        : 'assets/images/stage/everyday-nursery.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: palette.isHalloween
                ? const [Color(0xFF281C3E), Color(0xFF1A1228)]
                : const [Color(0xFFE7EFF7), Color(0xFFF6EFE6)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Nursery scene backdrop
            Positioned.fill(
              child: Opacity(
                opacity: palette.isHalloween ? 0.85 : 0.92,
                child: Image.asset(
                  stageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Pumpkin moon accent in Halloween mode
            if (palette.isHalloween)
              Positioned(
                top: 10,
                right: 16,
                child: Image.asset(
                  'assets/images/stage/pumpkin-moon.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            // Sparkle overlay on check-in celebration
            if (showSparkle && palette.isHalloween)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      'assets/images/stage/costume-sparkle-cut.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

            // 5-layer Baby Paper-Doll
            Positioned(
              bottom: 4,
              child: BabyAvatar(
                need: need,
                tone: tone,
                expression: expression,
                poseOverride: poseOverride,
                size: avatarSize,
                hopAnimation: hopAnimation,
              ),
            ),

            // Top-left floating pill badge
            if (topLeftBadge != null)
              Positioned(top: 12, left: 12, child: topLeftBadge!),
          ],
        ),
      ),
    );
  }
}
