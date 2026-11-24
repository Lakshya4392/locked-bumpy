---
inclusion: always
---
# Content Rules & Verification Steering

## Content Record Schema
Every text line shown in the app comes from a structured content record:
```json
{
  "id": "iron_ask_01",
  "category": "ask",
  "need": "IRON",
  "mode": "both",
  "tone": "both",
  "text": "Iron snack? Lentils or beans, your pick.",
  "status": "draft",
  "approved_by": "",
  "approved_date": ""
}
```

Start every new or revised line as a draft with blank review fields. Record a reviewer and date only after that person approves the exact wording. A schema example and a passing test cannot establish approval.

## Review States
- `draft`: Newly authored line; gate test will fail if rendered in production.
- `needs_fix`: Flagged during review for revision.
- `approved`: Explicitly approved by Karan (MD) or team lead; permissible in build.
- `rejected`: Incompatible with vision or clinical safety.

## Content Gate Enforcement
CI test and git hook reject the build if:
1. Any rendered content record has `status != "approved"`.
2. Any baby-voice string contains words matching the banned list.
3. Any week between 4 and 42 lacks an approved card.
