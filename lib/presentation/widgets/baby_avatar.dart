import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';

/// Baby paper-doll avatar widget.
/// Renders the hand-drawn PNG costume for the current mode and [need],
/// with an emoji fallback if an asset fails to load.
class BabyAvatar extends StatelessWidget {
  const BabyAvatar({
    super.key,
    required this.need,
    this.size = 128,
    this.hopAnimation,
    this.showBackdrop = true,
  });

  final MaternalNeed need;
  final double size;
  final Animation<double>? hopAnimation;
  final bool showBackdrop;

  /// Resolves the PNG asset path for [need] in the given mode.
  static String assetPathFor({
    required bool isHalloween,
    required MaternalNeed need,
  }) {
    if (!isHalloween) return 'assets/images/everyday.png';
    return switch (need) {
      MaternalNeed.iron => 'assets/images/body-vampire.png',
      MaternalNeed.brain => 'assets/images/body-zombie.png',
      MaternalNeed.bones => 'assets/images/body-skeleton.png',
      MaternalNeed.water => 'assets/images/body-mummy.png',
      MaternalNeed.rest => 'assets/images/body-ghost.png',
      MaternalNeed.vitamin => 'assets/images/body-witch.png',
    };
  }

  /// Fallback emoji if the asset fails to decode in constrained environments.
  static String fallbackEmoji({
    required bool isHalloween,
    required MaternalNeed need,
  }) {
    if (!isHalloween) return '👶';
    return switch (need) {
      MaternalNeed.iron => '🧛',
      MaternalNeed.brain => '🧟',
      MaternalNeed.bones => '💀',
      MaternalNeed.water => '🩹',
      MaternalNeed.rest => '👻',
      MaternalNeed.vitamin => '🧙',
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final asset = assetPathFor(isHalloween: palette.isHalloween, need: need);

    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Center(
        child: Text(
          fallbackEmoji(isHalloween: palette.isHalloween, need: need),
          style: TextStyle(fontSize: size * 0.48),
        ),
      ),
    );

    final avatar = showBackdrop
        ? Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              color: palette.paperRaised,
              shape: BoxShape.circle,
              border: Border.all(
                color: need.color.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Padding(padding: const EdgeInsets.all(8), child: image),
          )
        : image;

    if (disableAnimations || hopAnimation == null) return avatar;

    return AnimatedBuilder(
      animation: hopAnimation!,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, hopAnimation!.value),
        child: child,
      ),
      child: avatar,
    );
  }
}
