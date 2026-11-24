import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';

Future<void> confirmStartFresh(BuildContext context, AppState state) async {
  final palette = AppPalette.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ConfirmDialog(
      palette: palette,
      title: 'Start a fresh day?',
      body: "Today's check-ins will reset. Your date and nickname stay.",
      confirmLabel: 'Yes, start fresh',
      confirmDestructive: false,
    ),
  );
  if (confirmed == true && context.mounted) {
    await state.clearTodayCheckIns();
  }
}

Future<void> confirmErase(BuildContext context, AppState state) async {
  final palette = AppPalette.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _ConfirmDialog(
      palette: palette,
      title: 'Erase everything?',
      body:
          'This removes your date, nickname, appearance, check-ins, and visit list. '
          'It cannot be undone.',
      confirmLabel: 'Yes, erase',
      confirmDestructive: true,
    ),
  );
  if (confirmed == true && context.mounted) {
    await state.eraseAll();
  }
}
// ── Shared confirm dialog ─────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.palette,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmDestructive,
  });

  final AppPalette palette;
  final String title;
  final String body;
  final String confirmLabel;
  final bool confirmDestructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: palette.paper,
      title: Text(
        title,
        style: TextStyle(
          color: palette.ink,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      content: Text(
        body,
        style: TextStyle(color: palette.inkSoft, fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Never mind', style: TextStyle(color: palette.inkSoft)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmDestructive
                ? AppPalette.eraseAccent
                : palette.accent,
            foregroundColor: confirmDestructive
                ? AppPalette.eraseInk
                : palette.accentText,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
