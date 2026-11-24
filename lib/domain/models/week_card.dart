import 'dart:convert';
import 'content_record.dart';

/// One baby-voice card for a gestational week.
class WeekCard {
  const WeekCard({
    required this.week,
    required this.mode,
    required this.babyLine,
    this.sizeObject,
    required this.status,
    required this.approvedBy,
    required this.approvedDate,
  });

  /// Gestational week number (4–42).
  final int week;

  /// `'everyday'` | `'halloween'` | `'both'`
  final String mode;

  /// 1–2 sentences, baby voice, ~20 words max.
  final String babyLine;

  /// Everyday-object size comparison (e.g. `'blueberry'`).
  /// Null until Karan approves a size line for this week.
  final String? sizeObject;

  /// `'approved'` | `'draft'`
  final String status;

  final String approvedBy;
  final String approvedDate;

  factory WeekCard.fromJson(Map<String, dynamic> j) => WeekCard(
    week: j['week'] as int,
    mode: j['mode'] as String,
    babyLine: j['baby_line'] as String,
    sizeObject: j['size_object'] as String?,
    status: j['status'] as String,
    approvedBy: j['approved_by'] as String? ?? '',
    approvedDate: j['approved_date'] as String? ?? '',
  );

  static List<WeekCard> listFromJsonString(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WeekCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the first approved card for [week] matching [mode].
  /// Cards with `mode == 'both'` match any palette mode.
  static WeekCard? findFor({
    required List<WeekCard> cards,
    required int week,
    required String mode,
  }) {
    for (final c in cards) {
      if (c.week != week) continue;
      if (c.status != 'approved') continue;
      if (c.mode != 'both' && c.mode != mode) continue;
      if (ContentGate.hasDatedReview(c.approvedBy, c.approvedDate) &&
          c.babyLine.trim().isNotEmpty &&
          ContentGate.bannedTerm(c.babyLine) == null &&
          ContentGate.bannedTerm(c.sizeObject ?? '') == null) {
        return c;
      }
    }
    return null;
  }
}
