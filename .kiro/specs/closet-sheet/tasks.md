# Tasks: Closet Sheet

## Rung 4 (due Sun 29 Nov)
- [x] 1. Add `costumeOverride` nullable field + `setCostumeOverride()` to `AppState`
- [x] 2. Update `TodayScreen` avatar to use `state.costumeOverride ?? state.todayNeed`
         (check-in tiles remain bound to `state.todayNeed`)
- [x] 3. Create `ClosetSheet` widget in `lib/presentation/sheets/closet_sheet.dart`
         — 2×3 grid of costume cards (PNG image + name + need name)
         — tapping calls `state.setCostumeOverride(need)` and closes sheet
- [x] 4. Add wardrobe `IconButton` to `TopBar` (visible only when `palette.isHalloween`)
- [x] 5. Unit test: `costumeOverride` does not affect `state.todayNeed` or `allChecked`
- [x] 6. Widget test: Closet sheet shows 6 cards; tapping one updates avatar but not check-ins
