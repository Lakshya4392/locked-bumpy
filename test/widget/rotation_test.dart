import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:little_bumpy/presentation/widgets/top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'rotating or widening the same window preserves Bumpy, the lamp and check-ins',
    (t) async {
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load(now: () => DateTime(2026, 11, 23));
      t.view.physicalSize = const Size(390, 844);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      final checkIn = find.byKey(ValueKey(state.todayNeed));
      await t.ensureVisible(checkIn);
      await t.tap(checkIn);
      await t.pumpAndSettle();
      for (final size in [
        const Size(844, 390),
        const Size(1024, 768),
        const Size(1440, 900),
        const Size(320, 568),
      ]) {
        t.view.physicalSize = size;
        await t.pumpAndSettle();
        final shell = t.getRect(find.byType(TopBar));
        expect(
          shell.width,
          size.width.clamp(
            0.0,
            size.height <= 600 && size.width >= 640 ? 860.0 : 440.0,
          ),
          reason: 'reading column at $size',
        );
        expect(shell.center.dx, closeTo(size.width / 2, .1));
        final art = t.getSize(find.byType(BumpyAvatar));
        expect(art, const Size(190, 190));
        final tooltip = state.isHalloween
            ? 'Switch to Everyday'
            : 'Switch to Halloween';
        await t.tap(find.byTooltip(tooltip));
        await t.pumpAndSettle();
        expect(state.isChecked(state.todayNeed.name), isTrue);
        expect(t.takeException(), isNull);
      }
      await t.pumpWidget(const SizedBox());
    },
  );
}
