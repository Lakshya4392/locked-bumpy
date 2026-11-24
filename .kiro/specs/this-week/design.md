# Design: This Week Tab

## WeekCard Model

```dart
class WeekCard {
  final int week;           // 4–42
  final String mode;        // 'everyday' | 'halloween' | 'both'
  final String babyLine;    // 1–2 sentences, baby voice, ~20 words
  final String? sizeObject; // e.g. 'blueberry' — null until Karan approves
  final String status;      // 'approved' | 'draft'
  final String approvedBy;
  final String approvedDate;
}
```

## week_cards.json shape
```json
[
  {
    "week": 10,
    "mode": "both",
    "baby_line": "I am the size of a strawberry right now.",
    "size_object": "strawberry",
    "status": "draft",
    "approved_by": "",
    "approved_date": ""
  }
]
```
One entry per week per mode. Where mode is "both", a single card renders in both palettes.

## ThisWeekScreen layout
```
┌─────────────────────────────┐
│  ← Week 23  →               │
│  ┌───────────────────────┐  │
│  │  🌙  Week 23           │  │
│  │  "I am the size of... │  │
│  │  Your doctor chose... │  │
│  └───────────────────────┘  │
│  [< prev week]  [next week >]│
└─────────────────────────────┘
```
- `PageView.builder` driven by `_selectedWeek` local int (default: current week).
- Left/right `IconButton` arrows + swipe gesture.
- Current week dot indicator at top.
- No scrubber (cut order item 9 — only add if time allows).

## Week content coverage plan
- Weeks 4–12: Karan to approve short baby lines by Rung 2 (Wed 25 Nov).
- Weeks 13–28: Rung 3 (Fri 27 Nov).
- Weeks 29–42: Rung 4 (Sun 29 Nov).
- Placeholder line for unapproved weeks: shown only in dev/test, never in release build.
