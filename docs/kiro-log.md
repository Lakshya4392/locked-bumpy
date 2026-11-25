# Kiro Daily Log

## 2026-11-22 (Sun) - Lakshya
- **Kiro features used:** Project scaffolding, `.kiro/steering/`, `.kiro/hooks/`, `dart-check` hook setup.
- **What Kiro got right:** Clean configuration of Dart MCP and Flutter project targets for Android & Web.
- **What was overridden & why:** Preserved old habit app history on an archive branch while ensuring clean-room rebuild of Little Bumpy.
- **Credits used:** 0 (initial setup and local configuration).

## 2026-11-23 (Mon) - Kiro / Rung 1 complete
- **Specs closed:** `app-shell-and-theme` tasks 9 & 10; `today` tasks 2, 3, 4.
- **What was built:**
  - `shared_preferences ^2.3.3` added; 100% on-device persistence, zero network.
  - `AppConstants` — single source of truth for prefs keys, week bounds, disclaimer, rotation epoch.
  - `PrefsService` — thin prefs wrapper; date stored as ISO string, check-ins as comma-separated IDs, day boundary handled on load (blank slate each new day, no guilt, no mention of yesterday).
  - `NeedRotation` — deterministic 6-day cycle from epoch 2026-11-23; thirdCheckIn rule (REST when need is WATER or VITAMIN).
  - `AppState` (ChangeNotifier) — central state; notifyListeners fires before prefs await so UI rebuilds instantly.
  - `FirstRunScreen` — due date / LMP picker, persists to prefs, shows medical disclaimer; no accounts, no network.
  - `PausedScreen` — extracted to standalone widget; app voice only, no baby, no costume.
  - `TodayScreen` — full daily loop: costume tag, baby greeting, 3 check-ins, hop animation (respects reduce-motion), thank-you line, all-done line.
  - `ThisWeekScreen` / `GuidesScreen` — scaffolded placeholders for Rung 2.
  - `TopBar` / `AppNavBar` — extracted reusable widgets.
  - `main.dart` — rewired to async AppState.load(); isFirstRun → FirstRun, isPaused → Paused, else MainShell.
  - `ci.yml` — explicit content-gate step added; pinned to flutter 3.44.4.
- **Hooks:** `dart-check` (format + analyze) ✅ 0 issues. `content-check` ✅ all pass.
- **Tests:** 16 passed, 0 failed. Includes parity test (Halloween == Everyday InkWell count).
- **Content violations caught & fixed:** `'Floating peacefully'` (banned: floating) → `'Resting quietly'`; `'Potion — no, vitamin'` (banned: potion) → `'Vitamin secured'`; Tween type error `int` vs `double` on hop animation.
- **Credits used:** 1 session (Rung 1 full implementation).

## 2026-11-23 (Mon) - Kiro / Task 10 full completion
- **Spec:** `app-shell-and-theme` task 10 — gap audit and full implementation.
- **Gap audit result:** Previous session checked off task 10 but three features were missing: gestational week preview on date pick, optional baby nickname, and Halloween/Everyday look selector on the onboarding screen itself.
- **What was added:**
  - `AppConstants.prefsNicknameKey` — new prefs key `'baby_nickname'`.
  - `PrefsService.nickname` / `saveNickname` — reads/writes trimmed string on-device.
  - `AppState._nickname`, `.nickname`, `.babyDisplayName`, `.saveNickname()` — nickname in central state; `babyDisplayName` returns nickname if set, otherwise `'Little Bumpy'`.
  - `FirstRunScreen` rewritten as a 3-step `PageView` flow:
    - **Step 1 (Date):** Due Date / Last Period toggle, date picker, _live gestational week preview chip_ (`_WeekPreview`) computed via `PregnancyCalculator` immediately after date is chosen.
    - **Step 2 (Nickname):** Optional `TextField` (max 24 chars), skip-able.
    - **Step 3 (Look):** Two side-by-side `_LookCard` widgets — `🎃 Halloween` and `☀️ Everyday` — with animated selection border. Confirm persists look choice, nickname, and due date in a single call sequence.
  - `_StepIndicator` animated dots (shrinks inactive, expands active).
  - Mode is applied live during onboarding (palette switches as user picks a look on step 3).
- **New test file:** `test/widget/first_run_test.dart` — 10 tests covering step 1 structure, disclaimer, step dots, parity (Halloween == Everyday GestureDetector count), and all 4 nickname edge cases.
- **Hooks:** `dart-check` ✅ 0 changed. `content-check` ✅ all pass.
- **Tests:** 26 passed, 0 failed (all previous tests still green).

## 2026-11-23 (Mon) - Kiro / Full spec build-out & master plan
- **What this session did:** Full audit of every spec vs actual code; created all missing spec files; created master plan.
- **Spec files created:**
  - `content-packs-and-gate/` — added `requirements.md`, `design.md`, `tasks.md`
  - `this-week/` — added `requirements.md`, `design.md`, `tasks.md`
  - `baby-paper-doll/` — added `requirements.md`, `design.md`, `tasks.md`
  - `costumes-halloween/` — added `requirements.md`, `design.md`, `tasks.md`
  - `pause/` — added `requirements.md`, `design.md`, `tasks.md`
  - `guides/` — added `requirements.md`, `design.md`, `tasks.md`
  - `settings/` — NEW spec (requirements.md, design.md, tasks.md)
  - `closet-sheet/` — NEW spec (requirements.md, design.md, tasks.md)
  - `master-plan/` — NEW spec (requirements.md, tasks.md) — full 6-rung delivery ladder
- **Gaps found:**
  - Baby voice lines were hardcoded strings, not from JSON → ContentRecord system is Rung 2 blocker
  - PNG assets exist in `assets/images/` but not registered in pubspec.yaml → Rung 3 blocker
  - PausedScreen missing Start Fresh + Erase (spec req R5/R6) → Rung 2 work
  - No Settings screen → Rung 3
  - No Closet sheet → Rung 4
  - No GuideArticle model or JSON → Rung 4
- **Hooks post-audit:** `dart-check` ✅ 0 issues. `content-check` ✅ 3/3 pass.
- **Tests unchanged:** 26 passed, 0 failed.
- **Next session goal:** Execute all Rung 2 tasks (ContentRecord, JSON packs, ThisWeekScreen, Pause Start Fresh/Erase).

## 2026-11-25 (Wed) - Rungs 3 & 4 Complete (Paper-Doll, Closet, Guides, Settings)
- **Specs closed:** `baby-paper-doll`, `closet-sheet`, `guides`, `settings`.
- **What was built:**
  - `BabyAvatar` (`lib/presentation/widgets/baby_avatar.dart`) — renders real hand-drawn PNG costumes (`everyday.png`, `body-vampire.png`, `body-zombie.png`, `body-skeleton.png`, `body-mummy.png`, `body-ghost.png`, `body-witch.png`) with emoji fallback and `disableAnimations` support; wired into `TodayScreen` and `ThisWeekScreen`.
  - `AppState.costumeOverride` + `ClosetSheet` (`lib/presentation/sheets/closet_sheet.dart`) — 2×3 costume try-on grid opened from the `TopBar` wardrobe icon in Halloween mode; never alters `todayNeed` or daily check-in state.
  - `GuideArticle` + `assets/content/guide_articles.json` + `GuidesScreen` — 6 physician-authored maternal care guides (Iron, Brain, Bones, Water, Rest, Vitamin) with vegetarian/egg-free food ideas, doctor questions, and disclaimer footer.
  - `SettingsScreen` (`lib/presentation/screens/settings_screen.dart`) — nickname edit, due date picker, mode toggle, `AppConstants.appVersion`, `AppConstants.privacyStatement`, medical disclaimer, and `Erase all data` confirmation.
- **New tests:** `baby_avatar_test.dart`, `closet_sheet_test.dart`, `guides_screen_test.dart`, `settings_screen_test.dart` (plus dynamic `todayIso` fix in `pause_test.dart`).
- **Credits used:** 0 (local spec-driven build following `.kiro/steering/` and `.kiro/specs/`).
