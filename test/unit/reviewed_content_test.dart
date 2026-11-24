import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/week_card.dart';

void main() {
  test('missing review fields are withheld rather than crashing the loader', () {
    final week = WeekCard.listFromJsonString(
      '[{"week":10,"mode":"both","baby_line":"Hello.","status":"approved"}]',
    );
    expect(WeekCard.findFor(cards: week, week: 10, mode: 'everyday'), isNull);
    final records = ContentRecord.listFromJsonString(
      '[{"id":"fixture","category":"greeting","need":"IRON","mode":"both","tone":"both","text":"Hello.","status":"approved"}]',
    );
    expect(
      () => ContentGate.validateAll(records),
      throwsA(isA<ContentGateException>()),
    );
  });
  ContentRecord line(String reviewer, String date) => ContentRecord(
    id: 'fixture',
    category: 'greeting',
    need: 'IRON',
    mode: 'both',
    tone: 'both',
    text: 'Hello.',
    status: 'approved',
    approvedBy: reviewer,
    approvedDate: date,
  );
  WeekCard card(
    String reviewer,
    String date, {
    String text = 'Hello.',
    String? size,
  }) => WeekCard(
    week: 10,
    mode: 'both',
    babyLine: text,
    sizeObject: size,
    status: 'approved',
    approvedBy: reviewer,
    approvedDate: date,
  );
  WeekCard? find(WeekCard candidate) =>
      WeekCard.findFor(cards: [candidate], week: 10, mode: 'everyday');
  for (final (reviewer, date) in [
    ('', '2024-02-29'),
    ('   ', '2024-02-29'),
    ('Test reviewer', '2025-02-29'),
    ('Test reviewer', '2026-11-23T00:00:00'),
  ]) {
    test(
      'Today and Week require a named review and real date [$reviewer, $date]',
      () {
        expect(
          () => ContentGate.validate(line(reviewer, date)),
          throwsA(isA<ContentGateException>()),
        );
        expect(find(card(reviewer, date)), isNull);
      },
    );
  }
  test('a reviewed leap day is valid for both packs', () {
    expect(
      () => ContentGate.validate(line('Test reviewer', '2024-02-29')),
      returnsNormally,
    );
    expect(find(card('Test reviewer', '2024-02-29')), isNotNull);
  });
  test('weekly voice rules also cover the optional comparison', () {
    expect(
      find(card('Test reviewer', '2024-02-29', text: 'You missed it.')),
      isNull,
    );
    expect(find(card('Test reviewer', '2024-02-29', size: 'a potion')), isNull);
  });
}
