# Design: Content Packs and Gate

## ContentRecord Schema (Dart + JSON)

```dart
class ContentRecord {
  final String id;
  final String category;   // 'greeting' | 'thank_you' | 'goodbye'
  final String need;       // 'IRON' | 'BRAIN' | 'BONES' | 'WATER' | 'REST' | 'VITAMIN' | 'ALL'
  final String mode;       // 'everyday' | 'halloween' | 'both'
  final String tone;       // 'gentle' | 'cheeky' | 'both'
  final String text;
  final String status;     // 'draft' | 'needs_fix' | 'approved' | 'rejected'
  final String approvedBy;
  final String approvedDate;
}
```

Corresponding JSON (one object per line is fine; array of objects in file):

```json
{
  "id": "iron_greeting_hw_01",
  "category": "greeting",
  "need": "IRON",
  "mode": "halloween",
  "tone": "cheeky",
  "text": "I vant... lentils. Or beans. Your pick.",
  "status": "draft",
  "approved_by": "",
  "approved_date": ""
}
```

## Asset Paths
- `assets/content/today_lines.json` — all today-tab baby-voice lines (greetings, thank-yous, goodbyes).
- `assets/content/week_cards.json` — gestational week cards (weeks 4–42).
- `assets/content/guide_articles.json` — guide-tab app-voice content (Rung 4).

## ContentLoader
- Pure Dart class; loads JSON via `rootBundle.loadString(path)` (bundled, offline).
- Returns `List<ContentRecord>` after running every record through the gate.
- Throws `ContentGateException(record)` on first violation.
- Singleton or static loader; result cached after first load.

## Banned-word list (from voice.md, enforced in gate)
forgot, missed, should, must, sad, let down, wrong, lazy, streak, failed,
risk, danger, harm, "if you don't", kick, kicked, kick counter, move, moving,
roll, wriggle, hear, hearing, see, felt, tickle, death, died, dying, dead,
blood, decay, grave, bite, biting, undead, zombie brains, floating, fading,
gone, potion, spell, witch brew, partner, husband, father, weight, shape,
bump size, stretch marks, cravings.

## content-check hook upgrade
Current: runs `flutter test test/unit/content_gate_test.dart`
After: runs `flutter test test/unit/content_gate_test.dart` THEN
`dart run tool/validate_content.dart` which loads all JSON packs and
checks every record through ContentLoader.
(If `tool/validate_content.dart` is too heavy for Rung 2, the Flutter test
itself can load the JSON via `rootBundle` with `flutter test`.)
