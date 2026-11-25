import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/constants/app_constants.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _buildState({bool isHalloween = true}) async {
  SharedPreferences.setMockInitialValues({
    'due_date_iso': '2027-05-10',
    'is_halloween': isHalloween,
    'is_paused': false,
    'baby_nickname': 'Bumpy',
  });
  return AppState.load();
}

void main() {
  group('SettingsScreen', () {
    testWidgets('shows version, privacy statement, disclaimer, and erase', (
      tester,
    ) async {
      final state = await _buildState();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppPalette.halloween]),
          home: SettingsScreen(state: state),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(
        find.text('Little Bumpy v${AppConstants.appVersion}'),
        findsOneWidget,
      );
      expect(find.text(AppConstants.privacyStatement), findsOneWidget);
      expect(find.text(AppConstants.disclaimer), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Erase all data'), findsOneWidget);
    });

    testWidgets('parity: Everyday and Halloween render same controls', (
      tester,
    ) async {
      final everyday = await _buildState(isHalloween: false);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppPalette.everyday]),
          home: SettingsScreen(state: everyday),
        ),
      );
      await tester.pumpAndSettle();
      final everydayButtons = tester.widgetList(find.byType(InkWell)).length;

      final halloween = await _buildState(isHalloween: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppPalette.halloween]),
          home: SettingsScreen(state: halloween),
        ),
      );
      await tester.pumpAndSettle();
      final halloweenButtons = tester.widgetList(find.byType(InkWell)).length;

      expect(everydayButtons, equals(halloweenButtons));
    });
  });
}
