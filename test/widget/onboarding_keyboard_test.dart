import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _showOnboarding(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'is_halloween': true});
  final state = await AppState.load(now: () => DateTime(2026, 11, 23));
  await tester.pumpWidget(LittleBumpyApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void _expectFocused(WidgetTester tester, String label) {
  final target = find.bySemanticsLabel(label);
  expect(target, findsOneWidget);
  expect(
    tester.getSemantics(target).getSemanticsData().flagsCollection.isFocused,
    Tristate.isTrue,
    reason: 'Tab should focus $label.',
  );
}

void main() {
  testWidgets(
    'welcome sample has focus and both date modes are keyboard accessible',
    (tester) async {
      final state = await _showOnboarding(tester);

      await _press(tester, LogicalKeyboardKey.tab); // Pause
      await _press(tester, LogicalKeyboardKey.tab); // Lamp
      await _press(tester, LogicalKeyboardKey.tab);
      _expectFocused(tester, 'Try a sample check-in');
      await _press(tester, LogicalKeyboardKey.enter);
      expect(find.text('Sample only · nothing saved'), findsOneWidget);
      expect(state.completedCheckIns, isEmpty);

      await _press(tester, LogicalKeyboardKey.tab);
      _expectFocused(tester, 'Due Date');
      await _press(tester, LogicalKeyboardKey.tab);
      _expectFocused(tester, 'Last Period');
      await _press(tester, LogicalKeyboardKey.space);
      expect(find.text('Choose period start date'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await _press(tester, LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      _expectFocused(tester, 'Due Date');
      await _press(tester, LogicalKeyboardKey.enter);
      expect(find.text('Choose due date'), findsOneWidget);

      await _press(tester, LogicalKeyboardKey.tab);
      await _press(tester, LogicalKeyboardKey.tab);
      _expectFocused(tester, 'Pick your due date\nChoose due date');
      await _press(tester, LogicalKeyboardKey.space);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await _press(tester, LogicalKeyboardKey.escape);
      _expectFocused(tester, 'Pick your due date\nChoose due date');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('appearance cards can be focused and selected by keyboard', (
    tester,
  ) async {
    final state = await _showOnboarding(tester);
    tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(2);
    await tester.pumpAndSettle();

    await _press(tester, LogicalKeyboardKey.tab); // Pause
    await _press(tester, LogicalKeyboardKey.tab);
    _expectFocused(tester, 'Halloween. Midnight plum, pumpkin moon');
    await _press(tester, LogicalKeyboardKey.tab);
    const everyday = 'Everyday. Warm cream, storybook';
    _expectFocused(tester, everyday);
    await _press(tester, LogicalKeyboardKey.space);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(everyday))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(state.isHalloween, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
