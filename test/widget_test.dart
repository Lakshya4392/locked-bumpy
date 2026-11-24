import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/domain/models/need_rotation.dart';
import 'package:little_bumpy/presentation/screens/today_screen.dart';
import 'package:little_bumpy/presentation/screens/paused_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sets up a minimal [AppState] with a known due date so week display is
/// deterministic in tests.
Future<AppState> _buildState({
  bool isHalloween = false,
  bool isPaused = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'due_date_iso': '2027-05-10', // ~24 weeks from 2026-11-23
    'is_halloween': isHalloween,
    'is_paused': isPaused,
  });
  return AppState.load();
}

Widget _wrap(Widget child, AppState state) {
  final palette = state.isHalloween
      ? AppPalette.halloween
      : AppPalette.everyday;
  return MaterialApp(
    theme: ThemeData(extensions: [palette]),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TodayScreen smoke tests', () {
    testWidgets('renders 3 check-in tiles and disclaimer', (tester) async {
      final state = await _buildState();
      await tester.pumpWidget(_wrap(TodayScreen(state: state), state));
      await tester.pump();

      expect(find.text("Today's check-ins"), findsOneWidget);
      expect(
        find.text(
          'This app is not medical advice. '
          'If you are worried about anything, call your doctor.',
        ),
        findsOneWidget,
      );
      // Three tappable check-in tiles present.
      expect(find.byType(InkWell), findsAtLeastNWidgets(3));
    });

    testWidgets('ticking Need of the Day shows thank-you line', (tester) async {
      final state = await _buildState(isHalloween: false);
      await tester.pumpWidget(_wrap(TodayScreen(state: state), state));
      await tester.pump();

      final need = NeedRotation.forDate(DateTime.now());
      final tileTitle = '${need.needName} · Need of the Day';

      await tester.tap(find.text(tileTitle));
      await tester.pumpAndSettle();

      // Baby line should update to the thank-you line after tick.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.contains('Thank you') == true ||
                  w.data?.contains('cheer') == true),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'parity: Halloween and Everyday render same interactive element count',
      (tester) async {
        final everyday = await _buildState(isHalloween: false);
        await tester.pumpWidget(_wrap(TodayScreen(state: everyday), everyday));
        await tester.pump();
        final everydayInkWells = tester.widgetList(find.byType(InkWell)).length;

        final halloween = await _buildState(isHalloween: true);
        await tester.pumpWidget(
          _wrap(TodayScreen(state: halloween), halloween),
        );
        await tester.pump();
        final halloweenInkWells = tester
            .widgetList(find.byType(InkWell))
            .length;

        expect(everydayInkWells, equals(halloweenInkWells));
      },
    );
  });

  group('PausedScreen', () {
    testWidgets('shows no baby content, Resume, Start Fresh, Erase buttons', (
      tester,
    ) async {
      final state = await _buildState(isPaused: true);
      await tester.pumpWidget(_wrap(PausedScreen(state: state), state));
      await tester.pump();

      expect(find.text('Everything is paused.'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Start Fresh'), findsOneWidget);
      expect(find.text('Erase all data'), findsOneWidget);
      // No check-ins shown while paused.
      expect(find.text("Today's check-ins"), findsNothing);
      expect(find.text('Try Erase again'), findsNothing);
    });

    testWidgets('interrupted Erase shows a retry and disables Resume', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'erase_in_progress': true,
        'baby_nickname': 'Cub',
        'other_app_setting': 'preserved',
      });
      final state = await AppState.load();
      await tester.pumpWidget(_wrap(PausedScreen(state: state), state));
      await tester.pump();

      expect(find.textContaining('stays paused until Erase'), findsOneWidget);
      final resume = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Resume'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(resume.onPressed, isNull);

      await tester.tap(find.text('Try Erase again'));
      await tester.pump();
      expect(state.erasePending, isFalse);
      expect(state.isFirstRun, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'other_app_setting'});
    });
  });

  group('MaternalNeed', () {
    test('tag uses palette token, not a boolean', () {
      expect(
        MaternalNeed.iron.tag(AppPalette.halloween),
        equals('VAMPIRE · IRON'),
      );
      expect(
        MaternalNeed.iron.tag(AppPalette.everyday),
        equals('TODAY · IRON'),
      );
    });
  });
}
