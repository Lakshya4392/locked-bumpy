import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/constants/app_constants.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/presentation/screens/guides_screen.dart';

Widget _wrap(AppPalette palette, {Key? key}) {
  return MaterialApp(
    theme: ThemeData(extensions: [palette]),
    home: Scaffold(body: GuidesScreen(key: key)),
  );
}

Future<void> _pumpGuides(
  WidgetTester tester,
  AppPalette palette,
  Key key,
) async {
  await tester.pumpWidget(_wrap(palette, key: key));
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (find.byType(InkWell).evaluate().isNotEmpty) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  group('GuidesScreen', () {
    testWidgets('renders all 6 maternal care guides and disclaimer', (
      tester,
    ) async {
      await _pumpGuides(tester, AppPalette.everyday, const ValueKey('g1'));

      expect(find.text('Maternal Care Guides'), findsOneWidget);
      expect(find.text('Iron & Energy'), findsOneWidget);
      expect(find.text('Folate & Choline'), findsOneWidget);
      expect(find.text('Calcium & Vitamin D'), findsOneWidget);
      expect(find.text('Hydration'), findsOneWidget);
      expect(find.text('Rest & Comfort'), findsOneWidget);
      expect(find.text('Prenatal Vitamin'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text(AppConstants.disclaimer), findsOneWidget);
    });

    testWidgets('parity: Everyday and Halloween render same card count', (
      tester,
    ) async {
      await _pumpGuides(tester, AppPalette.everyday, const ValueKey('ev'));
      final everydayCount = tester.widgetList(find.byType(InkWell)).length;

      await _pumpGuides(tester, AppPalette.halloween, const ValueKey('hw'));
      final halloweenCount = tester.widgetList(find.byType(InkWell)).length;

      expect(everydayCount, equals(6));
      expect(everydayCount, equals(halloweenCount));
    });
  });
}
