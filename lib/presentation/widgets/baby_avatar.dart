import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';

/// Soft pastel gouache baby avatar with grounded breathing animation.
/// Renders [pastel-everyday-baby.png] in Everyday mode and the 6 pastel
/// Halloween costume PNGs in Halloween mode.
class BabyAvatar extends StatefulWidget {
  const BabyAvatar({
    super.key,
    required this.need,
    this.tone = AppConstants.defaultBabyTone,
    this.expression = 'calm',
    this.poseOverride,
    this.size = 156,
    this.hopAnimation,
    this.wiggleAnimation,
    this.animate = true,
  });

  final MaternalNeed need;
  final String tone;
  final String expression;
  final String? poseOverride;
  final double size;
  final Animation<double>? hopAnimation;
  final Animation<double>? wiggleAnimation;
  final bool animate;

  /// Resolves the pastel PNG asset path for [need] in the given mode.
  static String assetPathFor({
    required bool isHalloween,
    required MaternalNeed need,
  }) {
    if (!isHalloween) {
      return switch (need) {
        MaternalNeed.iron => 'assets/images/pastel-sailor-baby.png',
        MaternalNeed.brain => 'assets/images/pastel-story-baby.png',
        MaternalNeed.bones => 'assets/images/pastel-everyday-baby.png',
        MaternalNeed.water => 'assets/images/pastel-petal-baby.png',
        MaternalNeed.rest => 'assets/images/pastel-snuggle-baby.png',
        MaternalNeed.vitamin => 'assets/images/pastel-clap-baby.png',
      };
    }
    return switch (need) {
      MaternalNeed.iron => 'assets/images/pastel-vampire-baby.png',
      MaternalNeed.brain => 'assets/images/pastel-zombie-baby.png',
      MaternalNeed.bones => 'assets/images/pastel-skeleton-baby.png',
      MaternalNeed.water => 'assets/images/pastel-mummy-baby.png',
      MaternalNeed.rest => 'assets/images/pastel-ghost-baby.png',
      MaternalNeed.vitamin => 'assets/images/pastel-witch-baby.png',
    };
  }

  @override
  State<BabyAvatar> createState() => _BabyAvatarState();
}

class _BabyAvatarState extends State<BabyAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final Animation<double> _breatheScale;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.animate) {
      _breatheController.repeat(reverse: true);
    }
    _breatheScale = Tween<double>(begin: 1.0, end: 1.018).animate(
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
    final disableAnimations =
        !widget.animate || MediaQuery.disableAnimationsOf(context);
    if (disableAnimations && _breatheController.isAnimating) {
      _breatheController.stop();
    } else if (!disableAnimations && !_breatheController.isAnimating) {
      _breatheController.repeat(reverse: true);
    }

    final assetPath = BabyAvatar.assetPathFor(
      isHalloween: palette.isHalloween,
      need: widget.need,
    );

    final doll = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        child: Image.asset(
          assetPath,
          key: ValueKey(assetPath),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              palette.isHalloween ? '🎃' : '👶',
              style: TextStyle(fontSize: widget.size * 0.4),
            ),
          ),
        ),
      ),
    );

    if (disableAnimations) return doll;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breatheScale,
        if (widget.hopAnimation != null) widget.hopAnimation!,
        if (widget.wiggleAnimation != null) widget.wiggleAnimation!,
      ]),
      builder: (_, child) {
        final hop = widget.hopAnimation?.value ?? 0.0;
        final wiggle = widget.wiggleAnimation?.value ?? 0.0;
        return Transform.translate(
          offset: Offset(0, hop),
          child: Transform.rotate(
            angle: wiggle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: _breatheScale.value,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: doll,
    );
  }
}
