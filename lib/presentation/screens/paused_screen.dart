import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';

import '../widgets/data_confirmation.dart';

/// Quiet, neutral Paused screen.
/// App voice only — no baby, no costume, no animations.
class PausedScreen extends StatelessWidget {
  const PausedScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Still moon mark — no animation while paused.
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.moon.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Everything is paused.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.moonlight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Take all the time you need. '
                  'We are right here whenever you are ready.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: palette.moonlightSoft,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state.eraseFailed) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.erasePending
                        ? "Erase didn't finish. Some of your data may "
                              'already be removed, so the app stays paused '
                              'until Erase finishes.'
                        : "Erase didn't finish, so your data is still on "
                              'this device. Please try Erase again.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: palette.moonlight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Already confirmed once; retry goes straight to Erase.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.eraseAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.eraseAccent,
                        foregroundColor: AppPalette.eraseInk,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Try Erase again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 36),

                // Resume (disabled while an Erase is unfinished on disk)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.erasePending ? null : state.resume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.accentText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (state.dueDate != null) ...[
                  const SizedBox(height: 12),

                  // Start Fresh
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: state.erasePending
                          ? null
                          : () => confirmStartFresh(context, state),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.moonlightSoft,
                        side: BorderSide(
                          color: palette.moonlightSoft.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Start Fresh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Erase all data
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => confirmErase(context, state),
                    style: TextButton.styleFrom(
                      foregroundColor: AppPalette.eraseAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      'Erase all data',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
