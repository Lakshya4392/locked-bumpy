import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('finishing onboarding after midnight uses the new date', () async {
    SharedPreferences.setMockInitialValues({});
    var day = DateTime(2026, 11, 23, 23, 55);
    final state = await AppState.load(now: () => day);
    day = DateTime(2026, 11, 24);
    await state.saveDueDate(DateTime(2027, 5, 11));
    expect(state.daysTogetherCount, 112);
    expect(state.currentWeek, 16);
  });
  testWidgets('week, days together and check-ins follow the same local date', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-11'});
    var day = DateTime(2026, 11, 23, 23, 59);
    final state = await AppState.load(now: () => day);
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('111 days together'), findsOneWidget);
    await tester.tap(find.text('This Week'));
    await tester.pumpAndSettle();
    expect(find.text('Week 15'), findsWidgets);
    day = DateTime(2026, 11, 24);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Week 16'), findsNWidgets(2));
    expect(find.text('You are here'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('112 days together'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.textContaining('days together'), findsNothing);
    day = DateTime(2026, 12, 1);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('119 days together'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
