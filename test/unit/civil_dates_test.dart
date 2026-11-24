import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/pregnancy.dart';

void main() {
  test('calendar days round-trip through leap days and both clock changes', () {
    for (int start = 0; start < 366; start++) {
      final lmp = DateTime(2028, 1, 1 + start);
      final due = PregnancyCalculator.dueDateFromLmp(lmp);
      final expected = DateTime.utc(2028, 1, 1 + start + 280);
      expect(
        [due.year, due.month, due.day],
        [expected.year, expected.month, expected.day],
      );
      for (final offset in [28, 55, 56, 112, 280, 294]) {
        final now = DateTime(lmp.year, lmp.month, lmp.day + offset, 23, 40);
        expect(
          PregnancyCalculator.daysFromDueDate(dueDate: due, currentDate: now),
          offset,
        );
        expect(
          PregnancyCalculator.weekFromLmp(lmpDate: lmp, currentDate: now),
          offset ~/ 7,
        );
      }
    }
  });
  test('LMP and due dates use calendar days across spring daylight saving', () {
    expect(
      PregnancyCalculator.weekFromLmp(
        lmpDate: DateTime(2027, 1, 18),
        currentDate: DateTime(2027, 3, 15),
      ),
      8,
    );
    expect(
      PregnancyCalculator.weekFromDueDate(
        dueDate: DateTime(2027, 9, 14),
        currentDate: DateTime(2027, 2, 1),
      ),
      7,
    );
  });
}
