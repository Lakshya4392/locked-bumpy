import 'dart:convert';
import 'content_record.dart';
import 'need.dart';

/// Only reviewed articles reach the Guides tab. A draft leaves its need card
/// available, with the body and questions withheld until physician review.
class GuideArticle {
  const GuideArticle(this.body, this.questions);
  final String body;
  final List<String> questions;

  static Map<MaternalNeed, GuideArticle> reviewed(
    String json, {
    required String reviewer,
  }) {
    final articles = <MaternalNeed, GuideArticle>{};
    for (final row in (jsonDecode(json) as List).cast<Map<String, dynamic>>()) {
      if (row['status'] != 'approved') continue;
      final need = MaternalNeed.values.byName(
        (row['need'] as String).toLowerCase(),
      );
      final date = row['approved_date'] as String? ?? '';
      if (row['approved_by'] != reviewer ||
          !ContentGate.hasDatedReview(reviewer, date)) {
        throw FormatException('Missing physician review for ${need.name}');
      }
      final body = row['body'] as String;
      final questions = (row['questions'] as List).cast<String>();
      if (articles.containsKey(need) ||
          !body.trimRight().endsWith('Your doctor decides the amount.') ||
          questions.isEmpty ||
          questions.any((q) => !q.trimRight().endsWith('?')) ||
          [
            body,
            ...questions,
          ].any((line) => ContentGate.bannedTerm(line) != null)) {
        throw FormatException('Invalid reviewed article for ${need.name}');
      }
      articles[need] = GuideArticle(body, List.unmodifiable(questions));
    }
    return articles;
  }
}
