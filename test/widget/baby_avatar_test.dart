import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/presentation/widgets/baby_avatar.dart';

Widget _wrap(Widget child, AppPalette palette) {
  return MaterialApp(
    theme: ThemeData(extensions: [palette]),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('BabyAvatar', () {
    testWidgets('renders soft pastel baby in Everyday mode', (tester) async {
      await tester.pumpWidget(
        _wrap(const BabyAvatar(need: MaternalNeed.bones), AppPalette.everyday),
      );
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      final assets = images
          .map((i) => (i.image as AssetImage).assetName)
          .toList();
      expect(assets, contains('assets/images/pastel-everyday-baby.png'));
    });

    testWidgets(
      'renders soft pastel costume PNG for each need in Halloween mode',
      (tester) async {
        final expected = {
          MaternalNeed.iron: 'assets/images/pastel-vampire-baby.png',
          MaternalNeed.brain: 'assets/images/pastel-zombie-baby.png',
          MaternalNeed.bones: 'assets/images/pastel-skeleton-baby.png',
          MaternalNeed.water: 'assets/images/pastel-mummy-baby.png',
          MaternalNeed.rest: 'assets/images/pastel-ghost-baby.png',
          MaternalNeed.vitamin: 'assets/images/pastel-witch-baby.png',
        };

        for (final entry in expected.entries) {
          await tester.pumpWidget(
            _wrap(BabyAvatar(need: entry.key), AppPalette.halloween),
          );
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          final assets = images
              .map((i) => (i.image as AssetImage).assetName)
              .toList();
          expect(assets, contains(entry.value));
        }
      },
    );
  });
}
