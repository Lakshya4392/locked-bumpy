# Tasks: Content Packs and Gate

## Rung 2 (due Wed 25 Nov)
- [x] 1. Define initial Content Gate unit tests (planted bad records)
- [x] 2. Create `ContentRecord` Dart model (id, need, category, mode, tone, status, approved_by, approved_date)
- [x] 3. Create `ContentGateException` and gate validator function
- [x] 4. Create `assets/content/today_lines.json` with all 36 approved lines (6 needs × 3 categories × 2 modes)
- [x] 5. Create `ContentLoader` service using `rootBundle` (offline, bundled)
- [x] 6. Register `assets/content/` in `pubspec.yaml`
- [x] 7. Wire `TodayScreen` to load baby lines from `ContentLoader` instead of hardcoded strings
- [x] 8. Upgrade `content_gate_test.dart` to load and validate the real JSON pack
- [x] 9. Update `content-check` hook to run full JSON validation

## Rung 4 (due Sun 29 Nov)
- [ ] 10. Create `assets/content/guide_articles.json` with 6 approved guide-card bodies
- [ ] 11. Connect guide content to `GuidesScreen`
