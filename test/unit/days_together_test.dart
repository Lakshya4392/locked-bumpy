import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'legacy due date anchors the count through edits and missed days',
    () async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-04-12'});
      var today = DateTime(2026, 11, 23);
      Future<AppState> load() => AppState.load(now: () => today);

      var state = await load();
      expect(state.daysTogetherCount, 140);
      for (final need in state.dailyCheckIns) {
        await state.toggleCheckIn(need.name);
      }
      await state.saveDueDate(DateTime(2027, 4, 19));
      expect(state.currentWeek, 19);
      expect(state.daysTogetherCount, 140);
      state = await load();
      expect(state.allChecked, isTrue);
      expect(state.daysTogetherCount, 140);
      today = DateTime(2026, 11, 24);
      state.refreshDay();
      expect(state.daysTogetherCount, 141);
      today = DateTime(2026, 11, 28);
      state = await load();
      await state.saveDueDate(DateTime(2027, 4, 5));
      await state.clearTodayCheckIns();
      expect((await load()).daysTogetherCount, 145);

      await state.eraseAll();
      expect((await load()).daysTogetherCount, 0);
      await state.saveDueDate(DateTime(2027, 5, 15));
      expect(state.daysTogetherCount, 112);
      expect((await load()).daysTogetherCount, 112);
    },
  );
}
