import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import 'spring_tap.dart';

/// Floating glossy-pill bottom navigation bar (Today, Week, Guides, Settings).
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 4, 18, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: palette.tabBar,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isHalloween ? 0.38 : 0.07,
              ),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavPill(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Today',
              selected: state.currentTab == 0,
              palette: palette,
              onTap: () => state.setTab(0),
            ),
            _NavPill(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today_rounded,
              label: 'Week',
              selected: state.currentTab == 1,
              palette: palette,
              onTap: () => state.setTab(1),
            ),
            _NavPill(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book_rounded,
              label: 'Guides',
              selected: state.currentTab == 2,
              palette: palette,
              onTap: () => state.setTab(2),
            ),
            _NavPill(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Settings',
              selected: state.currentTab == 3,
              palette: palette,
              onTap: () => state.setTab(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pillGradient = palette.isHalloween
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.accent,
              Color.lerp(palette.accent, Colors.black, 0.16)!,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF393440), Color(0xFF17141C)],
          );

    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: SpringTap(
        onTap: onTap,
        pressedScale: 0.94,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 18 : 15,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              gradient: selected ? pillGradient : null,
              borderRadius: BorderRadius.circular(28),
              border: selected
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 1,
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: palette.isHalloween ? 0.3 : 0.18,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 20,
                  color: selected
                      ? palette.accentText
                      : palette.tabBarText.withValues(alpha: 0.45),
                ),
                if (selected) ...[
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.accentText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
