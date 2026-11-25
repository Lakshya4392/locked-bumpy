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
    testWidgets('renders 5-layer everyday paper-doll in Everyday mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const BabyAvatar(need: MaternalNeed.iron), AppPalette.everyday),
      );
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      final assets = images
          .map((i) => (i.image as AssetImage).assetName)
          .toList();
      expect(assets, contains('assets/images/bodies/everyday/peach.png'));
      expect(assets, contains('assets/images/heads/peach.png'));
      expect(assets, contains('assets/images/expressions/calm.png'));
    });

    testWidgets(
      'renders costume body + head + face for each need in Halloween mode',
      (tester) async {
        final expected = {
          MaternalNeed.iron: 'assets/images/bodies/vampire/peach.png',
          MaternalNeed.brain: 'assets/images/bodies/zombie/peach.png',
          MaternalNeed.bones: 'assets/images/bodies/skeleton/peach.png',
          MaternalNeed.water: 'assets/images/bodies/mummy/peach.png',
          MaternalNeed.rest: 'assets/images/bodies/ghost/peach.png',
          MaternalNeed.vitamin: 'assets/images/bodies/witch/peach.png',
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
          expect(assets, contains('assets/images/heads/peach.png'));
          expect(assets, contains('assets/images/expressions/calm.png'));
        }
      },
    );
  });
}
