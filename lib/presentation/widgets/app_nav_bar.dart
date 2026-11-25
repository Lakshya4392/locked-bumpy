import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import 'spring_tap.dart';

/// Floating capsule bottom navigation bar (Today, This Week, Guides).
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: palette.tabBar,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isHalloween ? 0.35 : 0.08,
              ),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavPill(
              icon: Icons.home_rounded,
              label: 'Today',
              selected: state.currentTab == 0,
              palette: palette,
              onTap: () => state.setTab(0),
            ),
            _NavPill(
              icon: Icons.calendar_today_rounded,
              label: 'This Week',
              selected: state.currentTab == 1,
              palette: palette,
              onTap: () => state.setTab(1),
            ),
            _NavPill(
              icon: Icons.menu_book_rounded,
              label: 'Guides',
              selected: state.currentTab == 2,
              palette: palette,
              onTap: () => state.setTab(2),
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
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: SpringTap(
        onTap: onTap,
        pressedScale: 0.94,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 18 : 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: selected ? palette.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? palette.accentText
                      : palette.tabBarText.withValues(alpha: 0.55),
                ),
                if (selected) ...[
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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
