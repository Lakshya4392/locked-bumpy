import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/domain/models/need_rotation.dart';

void main() {
  group('NeedRotation', () {
    test('epoch day 0 (2026-11-23) is IRON', () {
      expect(NeedRotation.forDate(DateTime(2026, 11, 23)), MaternalNeed.iron);
    });

    test('cycles through all 6 needs in 6 days', () {
      final epoch = DateTime(2026, 11, 23);
      final needs = List.generate(
        6,
        (i) => NeedRotation.forDate(epoch.add(Duration(days: i))),
      );
      expect(
        needs.toSet().length,
        6,
        reason: 'all 6 needs appear in one cycle',
      );
    });

    test('day 6 wraps back to IRON', () {
      expect(NeedRotation.forDate(DateTime(2026, 11, 29)), MaternalNeed.iron);
    });

    test('rotation advances one slot per local calendar date across DST', () {
      for (var i = 0; i < 250; i++) {
        final first = DateTime(2026, 11, 23 + i);
        final next = DateTime(first.year, first.month, first.day + 1);
        expect(
          NeedRotation.forDate(next).index,
          (NeedRotation.forDate(first).index + 1) % MaternalNeed.values.length,
        );
      }
    });

    test('thirdCheckIn returns REST when need is WATER', () {
      expect(NeedRotation.thirdCheckIn(MaternalNeed.water), MaternalNeed.rest);
    });

    test('thirdCheckIn returns REST when need is VITAMIN', () {
      expect(
        NeedRotation.thirdCheckIn(MaternalNeed.vitamin),
        MaternalNeed.rest,
      );
    });

    test('thirdCheckIn returns the need itself when it is IRON', () {
      expect(NeedRotation.thirdCheckIn(MaternalNeed.iron), MaternalNeed.iron);
    });
  });
}
