import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'old duplicate tiles preserve only the needs the user actually marked',
    () async {
      for (final day in [26, 27]) {
        final date = DateTime(2026, 11, day);
        SharedPreferences.setMockInitialValues({
          'checkin_date': '2026-11-$day',
          'checkin_ids': 'water,vitamin,need_of_the_day',
        });
        var state = await AppState.load(now: () => date);
        expect(state.completedCheckIns, {'water', 'rest'});
        expect(state.allChecked, isFalse);
        await state.toggleCheckIn('vitamin');
        state = await AppState.load(now: () => date);
        expect(state.allChecked, isTrue);
        await state.toggleCheckIn('water');
        state = await AppState.load(now: () => date);
        expect(state.completedCheckIns, {'vitamin', 'rest'});
      }
    },
  );

  test('a tap from yesterday cannot save old ticks into the new day', () async {
    var now = DateTime(2026, 11, 26, 23, 59);
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load(now: () => now);
    await state.toggleCheckIn('water');
    now = DateTime(2026, 11, 27);
    await state.toggleCheckIn('vitamin');
    expect(state.completedCheckIns, isEmpty);
    expect((await AppState.load(now: () => now)).completedCheckIns, isEmpty);
    await state.toggleCheckIn('rest');
    expect((await AppState.load(now: () => now)).completedCheckIns, {'rest'});
  });
}
