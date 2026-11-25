import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/constants/app_constants.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/presentation/sheets/closet_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _buildState() async {
  SharedPreferences.setMockInitialValues({
    'due_date_iso': '2027-05-10',
    'is_halloween': true,
    'is_paused': false,
  });
  return AppState.load();
}

void main() {
  group('ClosetSheet & costumeOverride', () {
    test('costumeOverride does not alter todayNeed or allChecked', () async {
      final state = await _buildState();
      final originalNeed = state.todayNeed;

      state.setCostumeOverride(MaternalNeed.vitamin);
      expect(state.costumeOverride, equals(MaternalNeed.vitamin));
      expect(state.todayNeed, equals(originalNeed));
      expect(state.allChecked, isFalse);

      await state.toggleCheckIn(AppConstants.checkInNeed);
      await state.toggleCheckIn(AppConstants.checkInWater);
      await state.toggleCheckIn(AppConstants.checkInVitamin);
      expect(state.allChecked, isTrue);
    });

    testWidgets('shows 6 costume cards and updates costumeOverride on tap', (
      tester,
    ) async {
      final state = await _buildState();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppPalette.halloween]),
          home: Scaffold(body: ClosetSheet(state: state)),
        ),
      );
      await tester.pump();

      expect(find.text('Costume Closet'), findsOneWidget);
      expect(find.text('Vampire'), findsOneWidget);
      expect(find.text('Zombie'), findsOneWidget);
      expect(find.text('Skeleton'), findsOneWidget);
      expect(find.text('Mummy'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Witch'), findsOneWidget);

      await tester.ensureVisible(find.text('Ghost'));
      await tester.tap(find.text('Ghost'));
      await tester.pumpAndSettle();

      expect(state.costumeOverride, equals(MaternalNeed.rest));
    });
  });
}
