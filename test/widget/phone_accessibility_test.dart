import 'package:flutter/material.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color text, Color surface) {
  final foreground = Color.alphaBlend(text, surface).computeLuminance();
  final background = surface.computeLuminance();
  return foreground >= background
      ? (foreground + .05) / (background + .05)
      : (background + .05) / (foreground + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(ContentLoader.loadWeekCards);
  testWidgets(
    'week title and unselected tab labels meet contrast in both looks',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'due_date_iso': '2027-04-10',
        'is_halloween': false,
      });
      final state = await AppState.load();
      state.setTab(1);
      await tester.pumpWidget(LittleBumpyApp(state: state));
      await tester.pumpAndSettle();

      for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
        final heading = tester.widget<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.style?.fontSize == 28 &&
                (w.data?.startsWith('Week ') ?? false),
          ),
        );
        expect(
          contrast(heading.style!.color!, palette.paper),
          greaterThanOrEqualTo(4.5),
        );
        final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(
          contrast(nav.unselectedItemColor!, palette.tabBar),
          greaterThanOrEqualTo(4.5),
        );
        if (!palette.isHalloween) {
          await tester.tap(find.byTooltip('Switch to Halloween'));
          await tester.pumpAndSettle();
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
    testWidgets(
      'input hints and erase confirmation have readable contrast in ${palette.isHalloween ? "Halloween" : "Everyday"}',
      (t) async {
        SharedPreferences.setMockInitialValues({
          'is_halloween': palette.isHalloween,
        });
        final state = await AppState.load();
        await t.pumpWidget(LittleBumpyApp(state: state));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Choose due date'));
        await t.tap(find.text('Choose due date'));
        await t.pumpAndSettle();
        await t.tap(find.text('OK'));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Choose name and appearance first'));
        await t.tap(find.text('Choose name and appearance first'));
        await t.pumpAndSettle();
        final decoration = t
            .widget<TextField>(find.byType(TextField))
            .decoration!;
        expect(
          contrast(decoration.hintStyle!.color!, decoration.fillColor!),
          greaterThanOrEqualTo(4.5),
          reason: 'nickname hint',
        );
        expect(
          contrast(decoration.counterStyle!.color!, palette.skyTop),
          greaterThanOrEqualTo(4.5),
          reason: 'character counter',
        );
        await state.saveDueDate(DateTime.now().add(const Duration(days: 100)));
        await state.togglePause();
        await t.pumpAndSettle();
        final erase = find.widgetWithText(TextButton, 'Erase all data');
        await t.ensureVisible(erase);
        final eraseStyle = t.widget<TextButton>(erase).style!;
        expect(
          contrast(eraseStyle.foregroundColor!.resolve({})!, palette.skyTop),
          greaterThanOrEqualTo(4.5),
          reason: 'erase action',
        );
        await t.tap(erase);
        await t.pumpAndSettle();
        final style = t
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Yes, erase'),
            )
            .style!;
        expect(
          contrast(
            style.foregroundColor!.resolve({})!,
            style.backgroundColor!.resolve({})!,
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'erase confirmation',
        );
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'a rotated phone keeps the main check-in beside the baby response',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(844, 390);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load(now: () => DateTime(2026, 11, 23));
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      final need = find.byKey(ValueKey(state.todayNeed));
      await t.tap(need.hitTestable());
      await t.pumpAndSettle();
      final thanks = find.text('Cape on. Thank you!');
      expect(thanks.hitTestable(), findsOneWidget);
      expect(t.getTopRight(thanks).dx, lessThan(t.getTopLeft(need).dx));
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets(
      'large text keeps check-ins and lamp controls usable at $size',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({
          'due_date_iso': DateTime.now()
              .add(const Duration(days: 140))
              .toIso8601String()
              .split('T')
              .first,
        });
        final state = await AppState.load(now: () => DateTime(2026, 11, 28));
        await tester.pumpWidget(LittleBumpyApp(state: state));
        await tester.pumpAndSettle();
        final controls = [
          find.byTooltip('Switch to Everyday'),
          find.widgetWithIcon(IconButton, Icons.settings_outlined),
          find.widgetWithIcon(IconButton, Icons.pause_circle_outline),
        ];
        expect(
          tester.getSize(find.byTooltip('Costume closet')).shortestSide,
          greaterThanOrEqualTo(48),
        );
        for (final control in controls) {
          final target = tester.getSize(control);
          expect(
            target.shortestSide,
            greaterThanOrEqualTo(48),
            reason: control.toString(),
          );
        }
        final tile = find.byKey(ValueKey(state.todayNeed));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: tile, matching: find.text('Done')),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Switch to Everyday'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: tile, matching: find.text('Done')),
          findsOneWidget,
        );
        await tester.tap(find.text('Guides'));
        await tester.pumpAndSettle();
        final guide = find.byKey(PageStorageKey(state.todayNeed));
        final heading = find.descendant(
          of: guide,
          matching: find.text(state.todayNeed.label),
        );
        await tester.dragUntilVisible(
          heading.hitTestable(),
          find.byType(ListView),
          const Offset(0, -70),
        );
        await tester.tap(heading.hitTestable());
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('assets/images/everyday.png')),
          findsOneWidget,
        );
        await tester.tap(find.text('This Week'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Next week'), findsOneWidget);
        final nextWeek = find.byIcon(Icons.arrow_forward_ios);
        await tester.dragUntilVisible(
          nextWeek.hitTestable(),
          find.byType(CustomScrollView),
          const Offset(0, -120),
        );
        await tester.tap(nextWeek.hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('You are here'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
