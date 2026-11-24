import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AppState> settings(WidgetTester t) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-11',
      'baby_nickname': 'Cub',
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await state.toggleCheckIn(state.todayNeed.name);
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Settings'));
    await t.pumpAndSettle();
    return state;
  }

  testWidgets('correct the due date without losing a saved check-in', (
    t,
  ) async {
    final state = await settings(t);
    final initial = state.completedCheckIns;
    final daysTogether = state.daysTogetherCount;
    final change = find.byTooltip('Change due date');
    expect(change, findsOneWidget);
    await t.ensureVisible(change);
    await t.tap(change);
    await t.pumpAndSettle();
    await t.tap(find.text('12').last);
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(state.dueDate, DateTime(2027, 5, 12));
    expect((await AppState.load()).dueDate, DateTime(2027, 5, 12));
    expect(state.currentWeek, 15);
    expect(state.daysTogetherCount, daysTogether);
    expect(state.completedCheckIns, initial);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('cancel, save, and clear a nickname without changing the look', (
    t,
  ) async {
    final state = await settings(t);
    final change = find.byTooltip('Edit nickname');
    expect(change, findsOneWidget);
    Future<void> edit(String input, String action) async {
      await t.ensureVisible(change);
      await t.tap(change);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), input);
      await t.tap(find.text(action));
      await t.pumpAndSettle();
    }

    await edit('discard', 'Cancel');
    expect(state.nickname, 'Cub');
    await edit('  Clover  ', 'Save');
    expect((await AppState.load()).nickname, 'Clover');
    await edit('', 'Save');
    expect(state.nickname, '');
    expect(state.isHalloween, isTrue);
    await t.pumpWidget(const SizedBox());
  });
}
