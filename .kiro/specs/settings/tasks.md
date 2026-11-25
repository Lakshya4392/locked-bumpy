# Tasks: Settings Screen

## Rung 3 (due Fri 27 Nov)
- [x] 1. Add `AppConstants.appVersion` and `AppConstants.privacyStatement`
- [x] 2. Create `SettingsScreen` widget in `lib/presentation/screens/settings_screen.dart`
         — app name + version, mode toggle, privacy statement, disclaimer, Erase button
- [x] 3. Add gear `IconButton` to `TopBar` → pushes `SettingsScreen` via `Navigator.push`
- [x] 4. Wire Erase button to `state.eraseAll()` with confirmation dialog
         (reuse dialog code from PausedScreen)
- [x] 5. Widget test: Settings shows version string, disclaimer, and privacy statement

## Rung 5 (due Tue 1 Dec)
- [x] 6. Verify Settings parity (Everyday == Halloween element count)
