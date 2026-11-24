import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/domain/models/guide_article.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ContentLoader.load('assets/content/today_lines.json');
    await ContentLoader.loadGuides();
  });
  for (var offset = 0; offset < 6; offset++) {
    testWidgets(
      'the lamp preserves the check-in and both voices on day $offset',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'due_date_iso': '2027-04-10',
          'is_halloween': false,
        });
        final date = DateTime(2026, 11, 23 + offset);
        final state = await AppState.load(now: () => date);
        final need = state.todayNeed;
        await tester.pumpWidget(LittleBumpyApp(state: state));
        await tester.pumpAndSettle();
        final records = await ContentLoader.load(
          'assets/content/today_lines.json',
        );
        for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
          final mode = palette.isHalloween ? 'halloween' : 'everyday';
          for (final ticked in [false, true]) {
            final line = ContentLoader.require(
              records: records,
              need: need.needName,
              category: ticked ? 'thank_you' : 'greeting',
              mode: mode,
            );
            expect(find.text(line.text), findsOneWidget);
            expect(
              find.byKey(ValueKey(need.assetPath(palette, happy: ticked))),
              findsOneWidget,
            );
            final tile = find.byKey(ValueKey(need));
            expect(
              find.descendant(of: tile, matching: find.byType(Image)),
              findsOneWidget,
            );
            if (!ticked) {
              await tester.ensureVisible(tile);
              await tester.tap(tile);
              await tester.pumpAndSettle();
            }
          }
          if (!palette.isHalloween) {
            await tester.tap(find.byTooltip('Switch to Halloween'));
            await tester.pumpAndSettle();
            expect(
              find.byKey(
                ValueKey(need.assetPath(AppPalette.halloween, happy: true)),
              ),
              findsOneWidget,
            );
            await tester.tap(find.byKey(ValueKey(need)));
            await tester.pumpAndSettle();
          }
        }
        final restored = await AppState.load(now: () => date);
        expect(restored.isHalloween, isTrue);
        expect(restored.isChecked(need.name), isTrue);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final need in MaternalNeed.values) {
    testWidgets('${need.name} guide opens in both looks and Pause hides it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'due_date_iso': '2027-04-10',
        'is_halloween': false,
      });
      final state = await AppState.load();
      final articles = GuideArticle.reviewed(
        File('assets/content/guide_articles.json').readAsStringSync(),
        reviewer: 'Karan',
      );
      await tester.pumpWidget(LittleBumpyApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guides'));
      await tester.pumpAndSettle();
      final tile = find.byKey(PageStorageKey(need));
      await tester.scrollUntilVisible(tile, 120);
      final heading = find.descendant(
        of: tile,
        matching: find.text(need.label),
      );
      await tester.dragUntilVisible(
        heading.hitTestable(),
        find.byType(ListView),
        const Offset(0, -60),
      );
      await tester.tap(heading.hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey(need.assetPath(AppPalette.everyday))),
        findsOneWidget,
      );
      if (!articles.containsKey(need)) {
        expect(find.text('Questions to ask your doctor'), findsNothing);
      }
      await tester.tap(find.byTooltip('Switch to Halloween'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey(need.assetPath(AppPalette.halloween))),
        findsOneWidget,
      );
      expect(find.text(need.costume), findsOneWidget);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Everything is paused.'), findsOneWidget);
      expect(find.byType(BumpyAvatar), findsNothing);
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Everything is paused.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
