import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/domain/models/skin_tone.dart';
import 'package:little_bumpy/presentation/widgets/paper_portrait.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'existing or unknown preferences use the original Peach master',
    () async {
      for (final value in [null, 'old-unknown-tone']) {
        SharedPreferences.setMockInitialValues({'skin_tone': ?value});
        final state = await AppState.load();
        expect(state.skinTone, SkinTone.peach);
        expect(
          paperPortrait('assets/images/everyday.png', state.skinTone),
          const AssetImage('assets/images/everyday.png'),
        );
        await state.saveSkinTone(SkinTone.deep);
        await state.eraseAll();
        expect((await AppState.load()).skinTone, SkinTone.peach);
      }
    },
  );
  testWidgets(
    'a saved skin tone follows Bumpy across both looks after a cold launch',
    (t) async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load(now: () => DateTime(2026, 11, 23));
      await state.toggleCheckIn(state.todayNeed.name);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      expect(find.text('Bumpy’s skin tone'), findsOneWidget);
      final choice = find.text('Deep umber');
      await t.ensureVisible(choice);
      await t.pumpAndSettle();
      await t.tap(choice.hitTestable());
      await t.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getString('skin_tone'),
        'deepest',
      );
      final preview = t.widget<Image>(
        find.byKey(const ValueKey('skin-tone-preview')),
      );
      expect(
        preview.image,
        const PaperTintImage('assets/images/everyday.png', SkinTone.deepest),
      );
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(state.completedCheckIns, {state.todayNeed.name});
      expect(
        find.byKey(const ValueKey('assets/images/body-vampire-happy.png')),
        findsOneWidget,
      );
      final avatar = t.widget<Image>(
        find.byKey(const ValueKey('assets/images/body-vampire-happy.png')),
      );
      expect(
        avatar.image,
        const PaperTintImage(
          'assets/images/body-vampire-happy.png',
          SkinTone.deepest,
        ),
      );
      await t.tap(find.byTooltip('Costume closet'));
      await t.pumpAndSettle();
      final costumes = t.widgetList<Image>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Image),
        ),
      );
      expect(costumes.length, 7);
      expect(
        costumes.every(
          (image) =>
              image.image is PaperTintImage &&
              (image.image as PaperTintImage).tone == SkinTone.deepest,
        ),
        isTrue,
      );
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Switch to Everyday'));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('assets/images/everyday-happy.png')),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
      final restored = await AppState.load(now: () => DateTime(2026, 11, 23));
      await t.pumpWidget(LittleBumpyApp(state: restored));
      await t.pumpAndSettle();
      expect(restored.completedCheckIns, {state.todayNeed.name});
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Deep umber'))
            .selected,
        isTrue,
      );
      await t.pumpWidget(const SizedBox());
    },
  );
}
