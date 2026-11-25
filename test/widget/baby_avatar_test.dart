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
    testWidgets('renders everyday.png in Everyday mode', (tester) async {
      await tester.pumpWidget(
        _wrap(const BabyAvatar(need: MaternalNeed.iron), AppPalette.everyday),
      );
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as AssetImage;
      expect(provider.assetName, equals('assets/images/everyday.png'));
    });

    testWidgets('renders costume PNG for each need in Halloween mode', (
      tester,
    ) async {
      final expected = {
        MaternalNeed.iron: 'assets/images/body-vampire.png',
        MaternalNeed.brain: 'assets/images/body-zombie.png',
        MaternalNeed.bones: 'assets/images/body-skeleton.png',
        MaternalNeed.water: 'assets/images/body-mummy.png',
        MaternalNeed.rest: 'assets/images/body-ghost.png',
        MaternalNeed.vitamin: 'assets/images/body-witch.png',
      };

      for (final entry in expected.entries) {
        await tester.pumpWidget(
          _wrap(BabyAvatar(need: entry.key), AppPalette.halloween),
        );
        final image = tester.widget<Image>(find.byType(Image));
        final provider = image.image as AssetImage;
        expect(provider.assetName, equals(entry.value));
      }
    });
  });
}
