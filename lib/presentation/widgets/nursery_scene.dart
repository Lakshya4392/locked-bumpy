import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import 'bumpy_avatar.dart';

/// The same paper room welcomes the parent and holds the daily visit.
class NurseryScene extends StatelessWidget {
  const NurseryScene({
    super.key,
    required this.palette,
    required this.avatar,
    this.cornerAction,
    this.height = 204,
  });
  final AppPalette palette;
  final BumpyAvatar avatar;
  final Widget? cornerAction;
  final double height;

  @override
  Widget build(BuildContext context) {
    final separateAction =
        cornerAction != null && MediaQuery.textScalerOf(context).scale(14) > 21;
    final room = SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Image.asset(
              palette.isHalloween
                  ? 'assets/images/nursery-halloween.png'
                  : 'assets/images/nursery-everyday.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.85),
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => ColoredBox(color: palette.skyBottom),
            ),
          ),
          SizedBox(
            height: height < 194 ? height - 4 : 190,
            child: FittedBox(child: avatar),
          ),
          if (cornerAction != null && !separateAction)
            Positioned(top: 6, left: 6, child: cornerAction!),
        ],
      ),
    );
    if (!separateAction) return room;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: cornerAction,
          ),
        ),
        room,
      ],
    );
  }
}
