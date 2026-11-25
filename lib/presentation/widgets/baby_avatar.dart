import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';

/// 5-layer studio paper-doll baby avatar with gentle breathing float,
/// gapless PNG rendering, and smooth expression crossfades.
class BabyAvatar extends StatefulWidget {
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
    if (!isHalloween) {
      return switch (need) {
        MaternalNeed.iron => 'sailor',
        MaternalNeed.brain => 'story',
        MaternalNeed.bones => 'everyday',
        MaternalNeed.water => 'petal',
        MaternalNeed.rest => 'snuggle',
        MaternalNeed.vitamin => 'clap',
      };
    }
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
  State<BabyAvatar> createState() => _BabyAvatarState();
}

class _BabyAvatarState extends State<BabyAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final Animation<double> _breatheOffset;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _breatheOffset = Tween<double>(begin: 1.0, end: 1.018).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations && _breatheController.isAnimating) {
      _breatheController.stop();
    } else if (!disableAnimations && !_breatheController.isAnimating) {
      _breatheController.repeat(reverse: true);
    }
    final safeTone = AppConstants.babyTones.contains(widget.tone)
        ? widget.tone
        : AppConstants.defaultBabyTone;

    final bodyPath = BabyAvatar.assetPathFor(
      isHalloween: palette.isHalloween,
      need: widget.need,
      tone: safeTone,
      poseOverride: widget.poseOverride,
    );
    final backExtra = BabyAvatar.backExtraFor(
      isHalloween: palette.isHalloween,
      need: widget.need,
      poseOverride: widget.poseOverride,
    );
    final headPath = 'assets/images/heads/$safeTone.png';
    final expressionPath = 'assets/images/expressions/${widget.expression}.png';
    final frontExtra = BabyAvatar.frontExtraFor(
      isHalloween: palette.isHalloween,
      need: widget.need,
      poseOverride: widget.poseOverride,
    );

    Widget layer(String path, {Key? key, bool withFallback = false}) {
      return Image.asset(
        path,
        key: key,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => withFallback
            ? Center(
                child: Text(
                  palette.isHalloween ? '🎃' : '👶',
                  style: TextStyle(fontSize: widget.size * 0.4),
                ),
              )
            : const SizedBox.shrink(),
      );
    }

    final useSoftPastelEveryday =
        !palette.isHalloween && widget.poseOverride == null;

    final doll = SizedBox(
      width: widget.size,
      height: widget.size,
      child: useSoftPastelEveryday
          ? layer('assets/images/pastel-everyday-baby.png', withFallback: true)
          : Stack(
              alignment: Alignment.center,
              children: [
                layer(bodyPath, withFallback: true),
                if (backExtra != null) layer(backExtra),
                layer(headPath),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: layer(expressionPath, key: ValueKey(expressionPath)),
                ),
                if (frontExtra != null) layer(frontExtra),
              ],
            ),
    );

    if (disableAnimations) return doll;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breatheOffset,
        if (widget.hopAnimation != null) widget.hopAnimation!,
      ]),
      builder: (_, child) {
        final hop = widget.hopAnimation?.value ?? 0.0;
        return Transform.translate(
          offset: Offset(0, hop),
          child: Transform.scale(
            scale: _breatheOffset.value,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: doll,
    );
  }
}
