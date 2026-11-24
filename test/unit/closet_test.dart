import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trying on a costume never changes or saves a care choice', () async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    DateTime clock() => DateTime(2026, 11, 23);
    final state = await AppState.load(now: clock);
    final daily = state.dailyCheckIns;
    for (final item in daily) {
      await state.toggleCheckIn(item.name);
    }
    state.setCostumeOverride(MaternalNeed.vitamin);
    expect(state.costumeOverride, MaternalNeed.vitamin);
    expect(state.todayNeed, MaternalNeed.iron);
    expect(state.dailyCheckIns, daily);
    expect(state.allChecked, isTrue);
    final restarted = await AppState.load(now: clock);
    expect(restarted.costumeOverride, isNull);
    expect(restarted.allChecked, isTrue);
    state.setCostumeOverride(state.todayNeed);
    expect(state.costumeOverride, isNull);
    state.setCostumeOverride(MaternalNeed.vitamin);
    await state.clearTodayCheckIns();
    expect(state.costumeOverride, isNull);
    state.setCostumeOverride(MaternalNeed.vitamin);
    await state.eraseAll();
    expect(state.costumeOverride, isNull);
    state.setCostumeOverride(MaternalNeed.vitamin);
    expect(state.costumeOverride, isNull);
  });
}
