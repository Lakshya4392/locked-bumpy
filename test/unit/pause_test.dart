import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _todayIso() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

void main() {
  group('Pause persistence', () {
    test('cold boot with is_paused=true loads in paused state', () async {
      SharedPreferences.setMockInitialValues({
        'is_paused': true,
        'due_date_iso': '2027-05-10',
      });
      final state = await AppState.load();
      expect(state.isPaused, isTrue);
    });

    test('cold boot with is_paused=false starts unpaused', () async {
      SharedPreferences.setMockInitialValues({
        'is_paused': false,
        'due_date_iso': '2027-05-10',
      });
      final state = await AppState.load();
      expect(state.isPaused, isFalse);
    });

    test('cold boot with no paused key defaults to false', () async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load();
      expect(state.isPaused, isFalse);
    });
  });

  group('AppState.clearTodayCheckIns', () {
    test('clears check-ins, unpauses, sets tab to 0', () async {
      SharedPreferences.setMockInitialValues({
        'due_date_iso': '2027-05-10',
        'is_paused': true,
        'checkin_date': _todayIso(),
        'checkin_ids': 'need_of_the_day,water',
      });
      final state = await AppState.load();
      expect(state.isChecked('water'), isTrue);
      expect(state.isPaused, isTrue);

      await state.clearTodayCheckIns();

      expect(state.completedCheckIns, isEmpty);
      expect(state.isPaused, isFalse);
      expect(state.currentTab, equals(0));
    });
  });

  group('AppState.eraseAll', () {
    test('resets all state — isFirstRun becomes true', () async {
      SharedPreferences.setMockInitialValues({
        'due_date_iso': '2027-05-10',
        'is_halloween': false,
        'is_paused': true,
        'baby_nickname': 'Peanut',
        'checkin_ids': 'water',
        'checkin_date': _todayIso(),
      });
      final state = await AppState.load();
      expect(state.isFirstRun, isFalse);
      expect(state.nickname, equals('Peanut'));

      await state.eraseAll();

      expect(state.isFirstRun, isTrue);
      expect(state.nickname, equals(''));
      expect(state.isHalloween, isTrue); // back to Halloween default
      expect(state.isPaused, isFalse);
      expect(state.completedCheckIns, isEmpty);
    });

    test('prefs are actually cleared after eraseAll', () async {
      SharedPreferences.setMockInitialValues({
        'due_date_iso': '2027-05-10',
        'baby_nickname': 'Sprout',
      });
      final state = await AppState.load();
      await state.eraseAll();

      // Loading a fresh state from same prefs instance should see no due date.
      final state2 = await AppState.load();
      expect(state2.isFirstRun, isTrue);
      expect(state2.nickname, equals(''));
    });
  });
}
