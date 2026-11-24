import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/constants/app_constants.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AppState> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-10',
      'baby_nickname': 'Cub',
    });
    final state = await AppState.load();
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Settings'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    return state;
  }

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('Pause hides the date editor at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final state = await open(tester);
      final edit = find.byTooltip('Change due date');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Pause').hitTestable());
      await tester.pumpAndSettle();
      expect(state.isPaused, isTrue);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.text('Everything is paused.'), findsOneWidget);
    });
  }

  testWidgets('Pause discards an unsaved nickname from the editor', (
    tester,
  ) async {
    final state = await open(tester);
    final edit = find.byTooltip('Edit nickname');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Unsaved');
    final pause = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byTooltip('Pause'),
    );
    await tester.tap(pause);
    await tester.pumpAndSettle();
    expect(state.isPaused, isTrue);
    expect(find.text('Unsaved'), findsNothing);
    expect((await AppState.load()).nickname, isNot('Unsaved'));
  });

  testWidgets('Settings has both looks, privacy, version and back to Guides', (
    tester,
  ) async {
    final state = await open(tester);
    expect(find.text('Little Bumpy'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(
      find.text(
        'No data ever leaves your phone. No accounts. No tracking. No ads.',
      ),
      findsOneWidget,
    );
    expect(find.text(AppConstants.disclaimer), findsOneWidget);
    await tester.tap(find.text('Everyday'));
    await tester.pumpAndSettle();
    expect(state.isHalloween, isFalse);
    expect((await AppState.load()).isHalloween, isFalse);
    expect(find.text(AppConstants.disclaimer), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(state.currentTab, 2);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Pause inside Settings quiets the app immediately', (
    tester,
  ) async {
    final state = await open(tester);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Everything is paused.'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(state.currentTab, 2);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Settings keeps Pause and its details reachable at 200% on a narrow phone',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final state = await open(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Pause').hitTestable(), findsOneWidget);
      final nickname = find.byTooltip('Edit nickname');
      await tester.ensureVisible(nickname);
      await tester.pumpAndSettle();
      expect(nickname.hitTestable(), findsOneWidget);
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(state.isPaused, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Pause clears an open nickname editor and its private text', (
    tester,
  ) async {
    final state = await open(tester);
    final edit = find.byTooltip('Edit nickname');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Unsaved nickname');
    await state.togglePause();
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Everything is paused.'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(state.nickname, 'Cub');
    expect(find.byType(TextFormField), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Settings and Pause use the same reversible erase confirmation', (
    tester,
  ) async {
    final state = await open(tester);
    final erase = find.text('Erase all data');
    await tester.dragUntilVisible(
      erase.hitTestable(),
      find.byType(ListView),
      const Offset(0, -160),
    );
    await tester.tap(erase);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Never mind'));
    await tester.pumpAndSettle();
    expect(state.nickname, 'Cub');
    await tester.tap(erase);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, erase'));
    await tester.pumpAndSettle();
    expect(state.isFirstRun, isTrue);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Choose due date'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
