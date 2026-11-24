import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/week_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('week_cards.json — coverage', () {
    late List<WeekCard> cards;

    setUpAll(() async {
      final raw = await rootBundle.loadString('assets/content/week_cards.json');
      cards = WeekCard.listFromJsonString(raw);
    });

    test('JSON parses without error', () {
      expect(cards, isNotEmpty);
    });

    test('there are exactly 39 cards (one per week 4–42)', () {
      expect(cards.length, equals(39));
    });

    test('every week 4–42 has at least one approved card', () {
      for (int w = 4; w <= 42; w++) {
        for (final mode in ['everyday', 'halloween']) {
          final card = WeekCard.findFor(cards: cards, week: w, mode: mode);
          expect(card, isNotNull, reason: 'No approved $mode card for week $w');
        }
      }
    });

    test('all cards have status=approved', () {
      for (final c in cards) {
        expect(
          c.status,
          equals('approved'),
          reason: 'card week=${c.week} has status ${c.status}',
        );
      }
    });

    test('no card has a week outside 4–42', () {
      for (final c in cards) {
        expect(c.week, inInclusiveRange(4, 42));
      }
    });
  });
}
