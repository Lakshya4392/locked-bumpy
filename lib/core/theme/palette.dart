import 'package:flutter/material.dart';

/// Design tokens for Little Bumpy (Storybook Night Nursery).
/// All color combinations guarantee >= 4.5:1 text contrast.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color skyTop;
  final Color skyBottom;
  final Color hill;
  final Color paper;
  final Color paperRaised;
  final Color ink;
  final Color inkSoft;
  final Color moonlight;
  final Color moonlightSoft;
  final Color moon;
  final Color accent;
  final Color accentText;
  final Color tabBar;
  final Color tabBarText;
  final bool isHalloween;

  const AppPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.hill,
    required this.paper,
    required this.paperRaised,
    required this.ink,
    required this.inkSoft,
    required this.moonlight,
    required this.moonlightSoft,
    required this.moon,
    required this.accent,
    required this.accentText,
    required this.tabBar,
    required this.tabBarText,
    required this.isHalloween,
  });

  static const everyday = AppPalette(
    skyTop: Color(0xFF3B2A4F),
    skyBottom: Color(0xFF2E2040),
    hill: Color(0xFF6E5585),
    paper: Color(0xFFFBF3E6),
    paperRaised: Color(0xFFF1E3CF),
    ink: Color(0xFF2E2040),
    inkSoft: Color(0xFF5E4D6E),
    moonlight: Color(0xFFF6EEDF),
    moonlightSoft: Color(0xFFCBBEDA),
    moon: Color(0xFFF5E2B0),
    accent: Color(0xFF9A3F6B),
    accentText: Color(0xFFFFF8EE),
    tabBar: Color(0xFFE8D9C4),
    tabBarText: Color(0xFF2E2040),
    isHalloween: false,
  );

  static const halloween = AppPalette(
    skyTop: Color(0xFF1A1224),
    skyBottom: Color(0xFF120C19),
    hill: Color(0xFF3A2B52),
    paper: Color(0xFF2A1F38),
    paperRaised: Color(0xFF382A4B),
    ink: Color(0xFFF3E9DA),
    inkSoft: Color(0xFFC9B9D9),
    moonlight: Color(0xFFF3E9DA),
    moonlightSoft: Color(0xFFB6A6C8),
    moon: Color(0xFFF0A45C), // Pumpkin moon
    accent: Color(0xFFF0A45C),
    accentText: Color(0xFF1A1224),
    tabBar: Color(0xFF120C19),
    tabBarText: Color(0xFFF3E9DA),
    isHalloween: true,
  );

  // Erase is displayed on the dark sky in both looks.
  static const eraseAccent = Color(0xFFFF8A80);
  static const eraseInk = Color(0xFF2E2040);

  // Six Need Colors (identical across both modes)
  static const needIron = Color(0xFFB8475E); // Leaf / vampire
  static const needBrain = Color(0xFF6E9A5B); // Round brain / zombie
  static const needBones = Color(0xFFE9E2D0); // Bone / skeleton
  static const needWater = Color(0xFF4F8FB8); // Water drop / mummy
  static const needRest = Color(0xFF9C8FD0); // Crescent moon / ghost
  static const needVitamin = Color(0xFFD9A23B); // Pill / witch

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? everyday;
  }

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? skyTop,
    Color? skyBottom,
    Color? hill,
    Color? paper,
    Color? paperRaised,
    Color? ink,
    Color? inkSoft,
    Color? moonlight,
    Color? moonlightSoft,
    Color? moon,
    Color? accent,
    Color? accentText,
    Color? tabBar,
    Color? tabBarText,
    bool? isHalloween,
  }) {
    return AppPalette(
      skyTop: skyTop ?? this.skyTop,
      skyBottom: skyBottom ?? this.skyBottom,
      hill: hill ?? this.hill,
      paper: paper ?? this.paper,
      paperRaised: paperRaised ?? this.paperRaised,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      moonlight: moonlight ?? this.moonlight,
      moonlightSoft: moonlightSoft ?? this.moonlightSoft,
      moon: moon ?? this.moon,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      tabBar: tabBar ?? this.tabBar,
      tabBarText: tabBarText ?? this.tabBarText,
      isHalloween: isHalloween ?? this.isHalloween,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      skyTop: Color.lerp(skyTop, other.skyTop, t)!,
      skyBottom: Color.lerp(skyBottom, other.skyBottom, t)!,
      hill: Color.lerp(hill, other.hill, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paperRaised: Color.lerp(paperRaised, other.paperRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      moonlight: Color.lerp(moonlight, other.moonlight, t)!,
      moonlightSoft: Color.lerp(moonlightSoft, other.moonlightSoft, t)!,
      moon: Color.lerp(moon, other.moon, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      tabBar: Color.lerp(tabBar, other.tabBar, t)!,
      tabBarText: Color.lerp(tabBarText, other.tabBarText, t)!,
      isHalloween: t < 0.5 ? isHalloween : other.isHalloween,
    );
  }
}
