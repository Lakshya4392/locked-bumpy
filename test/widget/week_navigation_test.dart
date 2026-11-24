import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('first and last week expose enabled native navigation buttons', (
    t,
  ) async {
    for (final (due, week) in [('2027-08-31', 4), ('2026-11-01', 42)]) {
      SharedPreferences.setMockInitialValues({'due_date_iso': due});
      final state = await AppState.load(now: () => DateTime(2026, 11, 24));
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.text('This Week'));
      await t.pumpAndSettle();
      final previous = find.widgetWithIcon(
        IconButton,
        Icons.arrow_back_ios_new,
      );
      final next = find.widgetWithIcon(IconButton, Icons.arrow_forward_ios);
      expect(previous, findsOneWidget);
      expect(t.widget<IconButton>(previous).onPressed == null, week == 4);
      expect(t.widget<IconButton>(next).onPressed == null, week == 42);
      await t.pumpWidget(const SizedBox());
    }
  });
  Future<void> openWeek(WidgetTester t, {bool reduceMotion = false}) async {
    if (reduceMotion) {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-11'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    await t.pumpAndSettle();
  }

  testWidgets(
    'a parent can jump to a distant week and come back to their own',
    (t) async {
      await openWeek(t);
      await t.tap(find.text('Choose week'));
      await t.pumpAndSettle();
      final last = find.text('42');
      await t.ensureVisible(last);
      await t.tap(last);
      await t.pumpAndSettle();
      expect(find.text('Week 42'), findsOneWidget);
      await t.tap(find.text('Back to this week'));
      await t.pumpAndSettle();
      expect(find.text('You are here'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('swipe reads the adjacent week and one tap comes home', (
    t,
  ) async {
    await openWeek(t);
    final card = find.text('You are here');
    expect(card, findsOneWidget);
    await t.drag(card, const Offset(-450, 0));
    await t.pumpAndSettle();
    expect(find.text('Week 17'), findsWidgets);
    final moon = find.image(const AssetImage('assets/images/need-rest.png'));
    expect(moon, findsAtLeastNWidgets(1));
    expect(
      t.widgetList<Image>(moon).every((image) => image.excludeFromSemantics),
      isTrue,
    );

    expect(find.text('You are here'), findsNothing);
    await t.tap(find.text('Back to this week'));
    await t.pumpAndSettle();
    expect(find.text('You are here'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('reduced motion arrows change week in the next frame', (t) async {
    await openWeek(t, reduceMotion: true);
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    await t.pump();
    expect(find.text('Week 15'), findsWidgets);
    await t.tap(find.text('Back to this week'));
    await t.pump();
    expect(find.text('You are here'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
