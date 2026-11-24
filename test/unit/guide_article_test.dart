import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/guide_article.dart';
import 'package:little_bumpy/domain/models/need.dart';

void main() {
  const reviewer = 'Test physician';
  const fixture = {
    'need': 'IRON',
    'body': 'Sample reviewed text. Your doctor decides the amount.',
    'questions': ['What can I ask?'],
    'status': 'approved',
    'approved_by': reviewer,
    'approved_date': '2026-11-23',
  };

  test('the bundled guide contains exactly one article per need', () {
    final json = File('assets/content/guide_articles.json').readAsStringSync();
    final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    expect(
      rows.map((row) => row['need']),
      unorderedEquals(MaternalNeed.values.map((n) => n.needName)),
    );
    for (final draft in rows.where((row) => row['status'] == 'draft')) {
      expect(draft['approved_by'], isEmpty);
      expect(draft['approved_date'], isEmpty);
    }
    expect(
      GuideArticle.reviewed(json, reviewer: 'Karan').length,
      rows.where((row) => row['status'] == 'approved').length,
    );
  });

  test('only reviewed articles reach the UI', () {
    final rows = [
      fixture,
      {
        ...fixture,
        'need': 'REST',
        'status': 'draft',
        'approved_by': '',
        'approved_date': '',
      },
      {...fixture, 'need': 'BONES', 'status': 'rejected'},
    ];
    final articles = GuideArticle.reviewed(
      jsonEncode(rows),
      reviewer: reviewer,
    );
    expect(articles.keys, [MaternalNeed.iron]);
    expect(articles[MaternalNeed.iron]!.questions, ['What can I ask?']);
    expect(articles[MaternalNeed.iron]!.body, fixture['body']);
  });

  test('incomplete reviews and banned language cannot publish a guide', () {
    for (final change in [
      {'approved_by': ''},
      {'approved_by': 'unassigned'},
      {'approved_date': '2026-02-31'},
      {'approved_date': ''},
      {'body': 'Incomplete ending.'},
      {'body': 'You forgot. Your doctor decides the amount.'},
      {
        'questions': ['Did you forget the streak?'],
      },
      {'questions': <String>[]},
      {
        'questions': ['Advice without a question'],
      },
    ]) {
      expect(
        () => GuideArticle.reviewed(
          jsonEncode([
            {...fixture, ...change},
          ]),
          reviewer: reviewer,
        ),
        throwsFormatException,
        reason: change.toString(),
      );
    }
    expect(
      () => GuideArticle.reviewed(
        jsonEncode([fixture, fixture]),
        reviewer: reviewer,
      ),
      throwsFormatException,
    );
  });
}
