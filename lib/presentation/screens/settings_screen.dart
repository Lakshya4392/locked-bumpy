import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../widgets/data_confirmation.dart';
import '../widgets/pregnancy_date_picker.dart';
import '../widgets/pause_button.dart';
import '../widgets/skin_tone_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  static Future<void> open(BuildContext context, AppState state) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: state,
          builder: (context, _) => SettingsScreen(state: state),
        ),
      ),
    );
  }

  Future<void> _editNickname(BuildContext context) async {
    var value = state.nickname;
    var saving = false;
    var failed = false;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, update) {
          Future<void> save() async {
            if (saving || state.isPaused) return;
            update(() {
              saving = true;
              failed = false;
            });
            final saved = await state.saveNickname(value);
            if (!context.mounted || state.isPaused || state.isFirstRun) return;
            if (saved) {
              Navigator.pop(context);
            } else {
              update(() {
                saving = false;
                failed = true;
              });
            }
          }

          return AlertDialog(
            scrollable: true,
            title: Row(
              children: [
                const Expanded(child: Text('Baby nickname')),
                PauseButton(
                  onPressed: state.pause,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            content: TextFormField(
              initialValue: value,
              autofocus: true,
              readOnly: saving,
              maxLength: 24,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nickname (optional)',
                errorText: failed ? 'Couldn’t save on this device.' : null,
              ),
              onChanged: (text) => value = text,
              onFieldSubmitted: (_) => save(),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: saving ? null : save,
                child: Text(failed ? 'Retry save' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final title = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: palette.ink,
      fontWeight: FontWeight.bold,
    );
    return Scaffold(
      backgroundColor: palette.skyBottom,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Row(
                  children: [
                    BackButton(color: palette.moonlight),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            color: palette.moonlight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Pause',
                      child: TextButton.icon(
                        onPressed: state.pause,
                        style: TextButton.styleFrom(
                          foregroundColor: palette.moonlight,
                        ),
                        icon: largeText
                            ? null
                            : const Icon(Icons.pause_circle_outline),
                        label: Text(largeText ? 'Pause' : 'Pause app'),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Card(
                        color: palette.paper,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _EditableDetail(
                                label: 'Due date',
                                value: state.dueDate == null
                                    ? ''
                                    : MaterialLocalizations.of(
                                        context,
                                      ).formatShortDate(state.dueDate!),
                                action: 'Change due date',
                                palette: palette,
                                onTap: () async {
                                  state.refreshDay();
                                  final picked = await pickPregnancyDate(
                                    context,
                                    today: state.today,
                                    useDueDate: true,
                                    onPause: state.pause,
                                    selected: state.dueDate,
                                  );
                                  if (picked != null &&
                                      context.mounted &&
                                      !state.isPaused &&
                                      !state.isFirstRun) {
                                    final saved = await state.saveDueDate(
                                      picked,
                                    );
                                    if (!saved &&
                                        context.mounted &&
                                        !state.isPaused) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Couldn’t save the due date. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              _EditableDetail(
                                label: 'Nickname',
                                value: state.babyDisplayName,
                                action: 'Edit nickname',
                                palette: palette,
                                onTap: () => _editNickname(context),
                              ),
                              const SizedBox(height: 16),
                              Text('Appearance', style: title),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final mode in [false, true])
                                    ChoiceChip(
                                      label: Text(
                                        mode ? 'Halloween' : 'Everyday',
                                      ),
                                      selected: mode == state.isHalloween,
                                      onSelected: (_) {
                                        if (mode != state.isHalloween) {
                                          state.toggleMode();
                                        }
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SkinTonePicker(
                                selected: state.skinTone,
                                onSelected: state.saveSkinTone,
                                foreground: palette.ink,
                                showPreview: true,
                              ),
                              const SizedBox(height: 24),
                              Text('Privacy', style: title),
                              const SizedBox(height: 4),
                              Text(
                                kIsWeb
                                    ? 'Your data stays in this browser on this device. No accounts. No tracking. No ads.'
                                    : AppConstants.privacyStatement,
                                style: TextStyle(color: palette.inkSoft),
                              ),
                              const SizedBox(height: 20),
                              Text('Medical disclaimer', style: title),
                              const SizedBox(height: 4),
                              Text(
                                AppConstants.disclaimer,
                                style: TextStyle(color: palette.inkSoft),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Little Bumpy', style: title),
                                  Text(
                                    AppConstants.appVersion,
                                    style: TextStyle(color: palette.inkSoft),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.moonlight,
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: () => confirmErase(context, state),
                          child: const Text('Erase all data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableDetail extends StatelessWidget {
  const _EditableDetail({
    required this.label,
    required this.value,
    required this.action,
    required this.palette,
    required this.onTap,
  });
  final String label;
  final String value;
  final String action;
  final AppPalette palette;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        title: Text(label, style: TextStyle(color: palette.ink)),
        subtitle: Text(value, style: TextStyle(color: palette.inkSoft)),
        trailing: Icon(Icons.edit_outlined, color: palette.inkSoft, size: 20),
      ),
    );
  }
}
