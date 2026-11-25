import 'dart:convert';
import 'need.dart';

/// A physician-authored maternal care guide card for one [MaternalNeed].
/// Uses calm, plain-English app voice — never baby voice, never clinical doses.
class GuideArticle {
  final String id;
  final String need;
  final String title;
  final String summary;
  final String body;
  final List<String> foodIdeas;
  final List<String> questionsForDoctor;
  final String status;

  const GuideArticle({
    required this.id,
    required this.need,
    required this.title,
    required this.summary,
    required this.body,
    required this.foodIdeas,
    required this.questionsForDoctor,
    required this.status,
  });

  factory GuideArticle.fromJson(Map<String, dynamic> json) {
    return GuideArticle(
      id: json['id'] as String,
      need: json['need'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      body: json['body'] as String,
      foodIdeas: (json['food_ideas'] as List<dynamic>).cast<String>(),
      questionsForDoctor: (json['questions_for_doctor'] as List<dynamic>)
          .cast<String>(),
      status: json['status'] as String,
    );
  }

  static List<GuideArticle> listFromJsonString(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => GuideArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  MaternalNeed get maternalNeed => MaternalNeed.values.firstWhere(
    (m) => m.needName == need,
    orElse: () => MaternalNeed.iron,
  );
}
