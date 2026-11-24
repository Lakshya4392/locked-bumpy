import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../screens/settings_screen.dart';

/// Week navigation and the nursery controls stay within reach on each tab.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, required this.state});

  final AppState state;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final currentWeek = state.currentWeek;
    final week = currentWeek == null ? '—' : 'Week $currentWeek';
    final switchLabel = state.isHalloween
        ? 'Switch to Everyday'
        : 'Switch to Halloween';
    final available = MediaQuery.sizeOf(context).width;
    final type = MediaQuery.textScalerOf(context).scale(14);
    final showLampLabel = available >= 350 && type <= 18;
    final weekChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.paperRaised.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.moonlight.withValues(alpha: .3)),
      ),
      child: Text(
        week,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: palette.moonlight,
        ),
      ),
    );
    final lamp = Image.asset(
      'assets/images/nursery-lamp.png',
      width: showLampLabel ? 24 : 36,
      height: showLampLabel ? 24 : 36,
      excludeFromSemantics: true,
      color: palette.isHalloween ? palette.moonlightSoft : null,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (_, _, _) =>
          Icon(Icons.lightbulb_outline, color: palette.moon),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: state.currentTab == 1
                ? weekChip
                : Tooltip(
                    message: 'Read this week’s card',
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        foregroundColor: palette.moonlight,
                      ),
                      onPressed: () => state.setTab(1),
                      child: weekChip,
                    ),
                  ),
          ),
          Row(
            children: [
              Tooltip(
                message: switchLabel,
                excludeFromSemantics: true,
                child: TextButton(
                  onPressed: state.toggleMode,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: palette.moonlight,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                  ),
                  child: Semantics(
                    label: '$switchLabel mode',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        lamp,
                        if (showLampLabel) ...[
                          const SizedBox(width: 4),
                          const Text('Switch look'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: Icon(Icons.settings_outlined, color: palette.moonlight),
                onPressed: () => SettingsScreen.open(context, state),
              ),
              Tooltip(
                message: 'Pause',
                excludeFromSemantics: true,
                child: IconButton(
                  icon: Icon(
                    Icons.pause_circle_outline,
                    semanticLabel: 'Pause app',
                    color: palette.moonlightSoft,
                  ),
                  onPressed: state.pause,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
