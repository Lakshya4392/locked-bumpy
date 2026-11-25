import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/pregnancy.dart';
import '../sheets/closet_sheet.dart';
import 'spring_tap.dart';

/// App top bar: baby & week pill + circular action buttons (Closet, Lamp, Pause, Settings).
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, required this.state});

  final AppState state;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final week = state.dueDate == null
        ? '—'
        : 'Week ${PregnancyCalculator.weekFromDueDate(dueDate: state.dueDate!, currentDate: DateTime.now())}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Baby name & gestational week pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: palette.paper,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: palette.isHalloween ? 0.25 : 0.05,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.moon,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${state.babyDisplayName} · $week',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),

          // Circular icon actions
          Row(
            children: [
              if (palette.isHalloween) ...[
                _CircleActionButton(
                  palette: palette,
                  label: 'Open costume closet',
                  tooltip: 'Costume closet',
                  icon: Icons.checkroom_rounded,
                  iconColor: palette.accent,
                  onTap: () => ClosetSheet.show(context, state),
                ),
                const SizedBox(width: 8),
              ],
              _CircleActionButton(
                palette: palette,
                label: state.isHalloween
                    ? 'Switch to Everyday mode'
                    : 'Switch to Halloween mode',
                tooltip: state.isHalloween
                    ? 'Switch to Everyday'
                    : 'Switch to Halloween',
                icon: state.isHalloween
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round,
                iconColor: palette.moon,
                onTap: state.toggleMode,
              ),
              const SizedBox(width: 8),
              _CircleActionButton(
                palette: palette,
                label: 'Pause app',
                tooltip: 'Pause',
                icon: Icons.pause_rounded,
                iconColor: palette.inkSoft,
                onTap: state.togglePause,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.palette,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final AppPalette palette;
  final String label;
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: SpringTap(
          onTap: onTap,
          pressedScale: 0.9,
          child: Material(
            color: palette.paper,
            shape: const CircleBorder(),
            elevation: palette.isHalloween ? 2 : 0.5,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(icon, size: 19, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
