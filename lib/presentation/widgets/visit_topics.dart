import 'package:flutter/material.dart';
import 'pause_button.dart';

import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';

/// A parent's private agenda. Selecting a topic never records a care action.
class VisitTopics extends StatelessWidget {
  const VisitTopics({super.key, required this.state});
  final AppState state;

  static Future<void> edit(
    BuildContext context,
    AppState state, {
    MaternalNeed? include,
  }) async {
    final palette = AppPalette.of(context);
    final selected = {...state.visitTopics, ?include};
    var saving = false;
    var saveFailed = false;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 440),
      backgroundColor: palette.paper,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) {
          Future<void> save() async {
            if (saving || state.isPaused || state.isFirstRun) return;
            update(() {
              saving = true;
              saveFailed = false;
            });
            try {
              await state.saveVisitTopics(selected);
            } catch (_) {
              if (context.mounted) {
                update(() {
                  saving = false;
                  saveFailed = true;
                });
              }
              return;
            }
            if (sheet.mounted && ModalRoute.of(sheet)?.isCurrent == true) {
              Navigator.pop(sheet);
            }
          }

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'For my next visit',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ),
                      PauseButton(onPressed: state.pause, color: palette.ink),
                      IconButton(
                        tooltip: 'Close visit list',
                        onPressed: () => Navigator.pop(sheet),
                        icon: Icon(Icons.close, color: palette.ink),
                      ),
                    ],
                  ),
                  Text(
                    'Choose what you want to ask your care team about.',
                    style: TextStyle(color: palette.inkSoft),
                  ),
                  const SizedBox(height: 8),
                  for (final need in MaternalNeed.values)
                    CheckboxListTile(
                      key: ValueKey('visit-topic-${need.name}'),
                      contentPadding: EdgeInsets.zero,
                      secondary: Image.asset(
                        need.iconPath,
                        width: 34,
                        height: 34,
                        excludeFromSemantics: true,
                      ),
                      activeColor: palette.accent,
                      checkColor: palette.accentText,
                      title: Text(
                        need.label,
                        style: TextStyle(color: palette.ink),
                      ),
                      value: selected.contains(need),
                      onChanged: saving
                          ? null
                          : (value) => update(() {
                              if (value == true) {
                                selected.add(need);
                              } else {
                                selected.remove(need);
                              }
                            }),
                    ),
                  const SizedBox(height: 10),
                  if (saveFailed)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Your visit list couldn’t be saved on this device.',
                          style: TextStyle(color: palette.ink),
                        ),
                      ),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.ink,
                      foregroundColor: palette.paper,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: saving ? null : save,
                    child: Text(
                      saving
                          ? 'Saving…'
                          : saveFailed
                          ? 'Retry save'
                          : 'Save visit list',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final topics = state.visitTopics;
    return Material(
      color: palette.paperRaised,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'For my next visit',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (topics.isEmpty)
              Text(
                'Keep a list of topics to ask your care team about.',
                style: TextStyle(color: palette.inkSoft),
              )
            else
              for (final need in MaternalNeed.values.where(topics.contains))
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      Image.asset(
                        need.iconPath,
                        width: 22,
                        height: 22,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          need.label,
                          style: TextStyle(color: palette.ink),
                        ),
                      ),
                    ],
                  ),
                ),
            TextButton.icon(
              onFocusChange: (focused) {
                if (!focused ||
                    FocusManager.instance.highlightMode !=
                        FocusHighlightMode.traditional) {
                  return;
                }
                final target = FocusManager.instance.primaryFocus?.context;
                if (target == null) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (target.mounted &&
                      FocusManager.instance.primaryFocus?.context == target) {
                    Scrollable.ensureVisible(target, alignment: .5);
                  }
                });
              },
              style: TextButton.styleFrom(foregroundColor: palette.ink),
              onPressed: () => edit(context, state),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(topics.isEmpty ? 'Choose topics' : 'Edit visit list'),
            ),
          ],
        ),
      ),
    );
  }
}
