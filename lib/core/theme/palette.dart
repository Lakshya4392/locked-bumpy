import 'package:flutter/material.dart';

/// Design tokens for Little Bumpy (Storybook Nursery — Pastel Everyday & Twilight Halloween).
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

  /// Warm pastel oat-cream & crisp white card palette (Everyday Nursery).
  static const everyday = AppPalette(
    skyTop: Color(0xFFF6F4EF),
    skyBottom: Color(0xFFEDE9E0),
    hill: Color(0xFFDAD3C5),
    paper: Color(0xFFFFFFFF),
    paperRaised: Color(0xFFF5F1EA),
    ink: Color(0xFF1F1926),
    inkSoft: Color(0xFF625A6D),
    moonlight: Color(0xFF1F1926),
    moonlightSoft: Color(0xFF625A6D),
    moon: Color(0xFFE6A74E),
    accent: Color(0xFF1E1A24),
    accentText: Color(0xFFFFFBF4),
    tabBar: Color(0xFFFFFFFF),
    tabBarText: Color(0xFF1E1A24),
    isHalloween: false,
  );

  /// Deep storybook twilight & velvet plum palette (Halloween Nursery).
  static const halloween = AppPalette(
    skyTop: Color(0xFF1D152B),
    skyBottom: Color(0xFF130E1D),
    hill: Color(0xFF3A2B52),
    paper: Color(0xFF2B203D),
    paperRaised: Color(0xFF372A4D),
    ink: Color(0xFFF6EFE4),
    inkSoft: Color(0xFFCBBCD9),
    moonlight: Color(0xFFF6EFE4),
    moonlightSoft: Color(0xFFBAAAD0),
    moon: Color(0xFFF2A45A), // Pumpkin moon
    accent: Color(0xFFF2A45A),
    accentText: Color(0xFF1A1224),
    tabBar: Color(0xFF231932),
    tabBarText: Color(0xFFF6EFE4),
    isHalloween: true,
  );

  // Six Need Colors (identical across both modes)
  static const needIron = Color(0xFFC44D64); // Leaf / vampire
  static const needBrain = Color(0xFF6E9A5B); // Brain / zombie
  static const needBones = Color(0xFFD4C4A8); // Bone / skeleton
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
