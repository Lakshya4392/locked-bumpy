import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/pregnancy.dart';
import '../screens/settings_screen.dart';
import '../sheets/closet_sheet.dart';

/// App top bar: week chip, lamp toggle, pause button.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, required this.state});

  final AppState state;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final week = state.dueDate == null
        ? '—'
        : 'Week ${PregnancyCalculator.weekFromDueDate(dueDate: state.dueDate!, currentDate: DateTime.now())}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gestational week chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: palette.paperRaised.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.moonlight.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              week,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.moonlight,
              ),
            ),
          ),

          Row(
            children: [
              // Costume closet — visible only in Halloween mode
              if (palette.isHalloween)
                Semantics(
                  label: 'Open costume closet',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      Icons.checkroom_outlined,
                      color: palette.moonlight,
                    ),
                    onPressed: () => ClosetSheet.show(context, state),
                    tooltip: 'Costume closet',
                  ),
                ),
              // Lamp toggle — switches Everyday ↔ Halloween
              Semantics(
                label: state.isHalloween
                    ? 'Switch to Everyday mode'
                    : 'Switch to Halloween mode',
                button: true,
                child: IconButton(
                  icon: Icon(
                    state.isHalloween
                        ? Icons.lightbulb_outline
                        : Icons.lightbulb,
                    color: palette.moon,
                  ),
                  onPressed: state.toggleMode,
                  tooltip: state.isHalloween
                      ? 'Switch to Everyday'
                      : 'Switch to Halloween',
                ),
              ),
              // Pause
              Semantics(
                label: 'Pause app',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.pause_circle_outline,
                    color: palette.moonlightSoft,
                  ),
                  onPressed: state.togglePause,
                  tooltip: 'Pause',
                ),
              ),
              // Settings
              Semantics(
                label: 'Settings',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: palette.moonlightSoft,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(state: state),
                    ),
                  ),
                  tooltip: 'Settings',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
