import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';

/// Bottom navigation bar: Today, This Week, Guides.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.tabBar,
        border: Border(
          top: BorderSide(color: palette.ink.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: state.currentTab,
        onTap: state.setTab,
        backgroundColor: palette.tabBar,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.tabBarText.withValues(alpha: 0.75),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: 'This Week',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Guides'),
        ],
      ),
    );
  }
}
