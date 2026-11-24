import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => ContentLoader.load('assets/content/today_lines.json'));

  testWidgets('six costumes can be tried on without changing the day', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    var day = DateTime(2026, 11, 23, 23, 58);
    final state = await AppState.load(now: () => day);
    await state.toggleCheckIn('iron');
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    final trigger = find.byTooltip('Costume closet');
    expect(trigger, findsOneWidget);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    for (final need in MaternalNeed.values) {
      final card = find.byKey(ValueKey('closet-${need.name}'));
      expect(
        find.descendant(of: card, matching: find.text(need.label)),
        findsOneWidget,
      );
    }
    final witch = find.byKey(const ValueKey('closet-vitamin'));
    await tester.ensureVisible(witch);
    await tester.tap(witch);
    await tester.pumpAndSettle();
    expect(state.costumeOverride, isNull);
    final wear = find.text('Wear Witch');
    await tester.ensureVisible(wear);
    await tester.tap(wear);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(
        ValueKey(
          MaternalNeed.vitamin.assetPath(AppPalette.halloween, happy: true),
        ),
      ),
      findsOneWidget,
    );
    expect(state.todayNeed, MaternalNeed.iron);
    expect(state.completedCheckIns, {'iron'});
    expect(find.text('IRON · Need of the Day'), findsOneWidget);
    expect(find.text('TODAY · IRON'), findsOneWidget);
    expect(find.text('Iron in. Thank you!'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to Everyday'));
    await tester.pumpAndSettle();
    expect(trigger, findsNothing);
    expect(
      find.byKey(const ValueKey('assets/images/everyday-happy.png')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Switch to Halloween'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('assets/images/body-witch-happy.png')),
      findsOneWidget,
    );
    day = DateTime(2026, 11, 24);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('assets/images/body-zombie.png')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('last costume is reachable at 200% text on a narrow phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 23));
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Costume closet'));
    await tester.pumpAndSettle();
    final witch = find.byKey(const ValueKey('closet-vitamin'));
    await tester.ensureVisible(witch);
    await tester.pumpAndSettle();
    await tester.tap(witch);
    await tester.pumpAndSettle();
    expect(state.costumeOverride, isNull);
    final wear = find.text('Wear Witch');
    await tester.ensureVisible(wear);
    await tester.tap(wear);
    await tester.pumpAndSettle();
    expect(state.costumeOverride, MaternalNeed.vitamin);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'the closet dismisses on Pause and can be cancelled without selecting',
    (tester) async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load();
      await tester.pumpWidget(LittleBumpyApp(state: state));
      await tester.pumpAndSettle();
      final trigger = find.byTooltip('Costume closet');
      expect(trigger, findsOneWidget);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      final witch = find.byKey(const ValueKey('closet-vitamin'));
      await tester.ensureVisible(witch);
      await tester.tap(witch);
      await tester.pumpAndSettle();
      expect(find.text('Wear Witch'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(state.costumeOverride, isNull);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      await state.togglePause();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(trigger, findsNothing);
      expect(find.text('Everything is paused.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
