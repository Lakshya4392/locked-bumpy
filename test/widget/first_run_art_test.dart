import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('the first visit shows Bumpy and a real preview of each look', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load(now: () => DateTime(2026, 11, 23));
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    Finder asset(String path) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == 'assets/images/$path.png',
    );
    expect(asset('body-vampire'), findsOneWidget);
    await tester.ensureVisible(find.text('Choose due date'));
    await tester.tap(find.text('Choose due date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    Future<void> next() async {
      final button = find.widgetWithText(ElevatedButton, 'Next');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    final personalize = find.text('Choose name and appearance first');
    await tester.ensureVisible(personalize);
    await tester.tap(personalize);
    await tester.pumpAndSettle();
    await next();
    expect(asset('everyday'), findsOneWidget);
    expect(asset('body-vampire'), findsOneWidget);
    expect(find.text('Halloween'), findsOneWidget);
    await tester.tap(find.text('Everyday'));
    await tester.pumpAndSettle();
    final start = find.text("Let's go");
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(state.isHalloween, isFalse);
    expect(
      find.byKey(const ValueKey('assets/images/everyday.png')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
