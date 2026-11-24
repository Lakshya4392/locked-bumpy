import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';

void main() {
  testWidgets(
    'all six needs use bundled, complete Bumpy pictures in both looks',
    (tester) async {
      for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
        for (final need in MaternalNeed.values) {
          for (final happy in [false, true]) {
            await tester.pumpWidget(
              MaterialApp(
                home: Center(
                  child: BumpyAvatar(
                    need: need,
                    palette: palette,
                    happy: happy,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final stem = palette.isHalloween
                ? 'body-${need.costume.toLowerCase()}'
                : 'everyday';
            final path = 'assets/images/$stem${happy ? '-happy' : ''}.png';
            expect(find.image(AssetImage(path)), findsOneWidget);
            expect(
              tester.getSize(find.byType(BumpyAvatar)),
              const Size.square(190),
            );
            expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
            expect(
              find.descendant(
                of: find.byType(BumpyAvatar),
                matching: find.byType(Text),
              ),
              findsNothing,
            );
            expect(
              find.bySemanticsLabel(RegExp('Bumpy in a ')),
              findsOneWidget,
            );
          }
        }
      }
    },
  );

  testWidgets('reduced motion swaps immediately and ignores the hop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: BumpyAvatar(
            need: MaternalNeed.water,
            palette: AppPalette.halloween,
            happy: true,
            hopAnimation: AlwaysStoppedAnimation(-18),
          ),
        ),
      ),
    );
    final root = find.byType(BumpyAvatar);
    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(of: root, matching: find.byType(AnimatedSwitcher)),
    );
    expect(switcher.duration, Duration.zero);
    expect(
      find.descendant(of: root, matching: find.byType(Transform)),
      findsNothing,
    );
  });
}
