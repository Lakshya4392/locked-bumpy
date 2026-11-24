import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

enum MaternalNeed {
  iron(
    needName: 'IRON',
    costume: 'VAMPIRE',
    color: AppPalette.needIron,
    foodHint: 'Lentils or beans',
  ),
  brain(
    needName: 'BRAIN',
    costume: 'ZOMBIE',
    color: AppPalette.needBrain,
    foodHint: 'Leafy greens or beans',
  ),
  bones(
    needName: 'BONES',
    costume: 'SKELETON',
    color: AppPalette.needBones,
    foodHint: 'Milk, yogurt or cheese',
  ),
  water(
    needName: 'WATER',
    costume: 'MUMMY',
    color: AppPalette.needWater,
    foodHint: 'A refreshing glass of water',
  ),
  rest(
    needName: 'REST',
    costume: 'GHOST',
    color: AppPalette.needRest,
    foodHint: 'Put your feet up for five',
  ),
  vitamin(
    needName: 'VITAMIN',
    costume: 'WITCH',
    color: AppPalette.needVitamin,
    foodHint: 'The vitamin your doctor chose',
  );

  final String needName;
  final String costume;
  final Color color;
  final String foodHint;

  const MaternalNeed({
    required this.needName,
    required this.costume,
    required this.color,
    required this.foodHint,
  });

  String get label => this == MaternalNeed.vitamin
      ? 'Prenatal Vitamin'
      : name[0].toUpperCase() + name.substring(1);

  String get iconPath => 'assets/images/need-$name.png';

  /// Returns the display tag. Reads [palette] so no boolean branch in callers.
  String tag(AppPalette palette) =>
      palette.isHalloween ? '$costume · $needName' : 'TODAY · $needName';

  String assetPath(AppPalette palette, {bool happy = false}) {
    final stem = palette.isHalloween
        ? 'body-${costume.toLowerCase()}'
        : 'everyday';
    return 'assets/images/$stem${happy ? '-happy' : ''}.png';
  }
}
