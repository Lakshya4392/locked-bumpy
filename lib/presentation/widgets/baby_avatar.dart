import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';

/// 5-layer studio paper-doll baby avatar.
/// Stacks at (0,0) in order: body -> back-extra -> head -> expression -> extra.
class BabyAvatar extends StatelessWidget {
  const BabyAvatar({
    super.key,
    required this.need,
    this.tone = AppConstants.defaultBabyTone,
    this.expression = 'calm',
    this.poseOverride,
    this.size = 156,
    this.hopAnimation,
  });

  final MaternalNeed need;
  final String tone;
  final String expression;
  final String? poseOverride;
  final double size;
  final Animation<double>? hopAnimation;

  /// Resolves the pose folder name for [need] in the given mode.
  static String poseFor({
    required bool isHalloween,
    required MaternalNeed need,
    String? poseOverride,
  }) {
    if (poseOverride != null) return poseOverride;
    if (!isHalloween) return 'everyday';
    return switch (need) {
      MaternalNeed.iron => 'vampire',
      MaternalNeed.brain => 'zombie',
      MaternalNeed.bones => 'skeleton',
      MaternalNeed.water => 'mummy',
      MaternalNeed.rest => 'ghost',
      MaternalNeed.vitamin => 'witch',
    };
  }

  /// Resolves the body PNG path (primary layer for tests & fallback).
  static String assetPathFor({
    required bool isHalloween,
    required MaternalNeed need,
    String tone = AppConstants.defaultBabyTone,
    String? poseOverride,
  }) {
    final pose = poseFor(
      isHalloween: isHalloween,
      need: need,
      poseOverride: poseOverride,
    );
    return 'assets/images/bodies/$pose/$tone.png';
  }

  static String? backExtraFor({
    required bool isHalloween,
    required MaternalNeed need,
    String? poseOverride,
  }) {
    if (!isHalloween || poseOverride != null) return null;
    return switch (need) {
      MaternalNeed.iron => 'assets/images/extras/vampire-collar.png',
      MaternalNeed.rest => 'assets/images/extras/ghost-cowl.png',
      MaternalNeed.water => 'assets/images/extras/mummy-streamer.png',
      _ => null,
    };
  }

  static String? frontExtraFor({
    required bool isHalloween,
    required MaternalNeed need,
    String? poseOverride,
  }) {
    if (!isHalloween || poseOverride != null) return null;
    return switch (need) {
      MaternalNeed.vitamin => 'assets/images/extras/witch-hat.png',
      MaternalNeed.bones => 'assets/images/extras/bone-bow.png',
      MaternalNeed.brain => 'assets/images/extras/zombie-cap.png',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final safeTone = AppConstants.babyTones.contains(tone)
        ? tone
        : AppConstants.defaultBabyTone;

    final bodyPath = assetPathFor(
      isHalloween: palette.isHalloween,
      need: need,
      tone: safeTone,
      poseOverride: poseOverride,
    );
    final backExtra = backExtraFor(
      isHalloween: palette.isHalloween,
      need: need,
      poseOverride: poseOverride,
    );
    final headPath = 'assets/images/heads/$safeTone.png';
    final expressionPath = 'assets/images/expressions/$expression.png';
    final frontExtra = frontExtraFor(
      isHalloween: palette.isHalloween,
      need: need,
      poseOverride: poseOverride,
    );

    Widget layer(String path, {bool withFallback = false}) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => withFallback
            ? Center(
                child: Text(
                  palette.isHalloween ? '🎃' : '👶',
                  style: TextStyle(fontSize: size * 0.4),
                ),
              )
            : const SizedBox.shrink(),
      );
    }

    final doll = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          layer(bodyPath, withFallback: true),
          if (backExtra != null) layer(backExtra),
          layer(headPath),
          layer(expressionPath),
          if (frontExtra != null) layer(frontExtra),
        ],
      ),
    );

    if (disableAnimations || hopAnimation == null) return doll;

    return AnimatedBuilder(
      animation: hopAnimation!,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, hopAnimation!.value),
        child: child,
      ),
      child: doll,
    );
  }
}
