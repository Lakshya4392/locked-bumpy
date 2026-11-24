import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import 'paper_portrait.dart';

/// Full-body paper cut on the same square registration in both nursery looks.
class BumpyAvatar extends StatelessWidget {
  const BumpyAvatar({
    super.key,
    required this.need,
    required this.palette,
    required this.happy,
    this.hopAnimation,
    this.skinTone = SkinTone.peach,
  });

  final MaternalNeed need;
  final AppPalette palette;
  final bool happy;
  final SkinTone skinTone;
  final Animation<double>? hopAnimation;

  @override
  Widget build(BuildContext context) {
    final path = need.assetPath(palette, happy: happy);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final look = palette.isHalloween
        ? '${need.costume.toLowerCase()} costume'
        : 'lavender onesie';
    final avatar = AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      child: Image(
        image: paperPortrait(path, skinTone),
        key: ValueKey(path),
        width: 190,
        height: 190,
        fit: BoxFit.contain,
        // Keep the same space and spoken description if an asset is damaged.
        errorBuilder: (context, error, stack) => SizedBox.square(
          dimension: 190,
          child: Icon(Icons.nightlight_round, color: palette.moon, size: 40),
        ),
      ),
    );
    final hop = hopAnimation;
    return Semantics(
      image: true,
      label: 'Bumpy in a $look${happy ? ', smiling' : ''}',
      excludeSemantics: true,
      child: reduceMotion || hop == null
          ? avatar
          : AnimatedBuilder(
              animation: hop,
              child: avatar,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, hop.value),
                child: child,
              ),
            ),
    );
  }
}
