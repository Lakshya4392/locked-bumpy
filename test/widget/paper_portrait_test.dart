import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/skin_tone.dart';
import 'package:little_bumpy/presentation/widgets/paper_portrait.dart';

Future<Uint8List> pixels(
  ImageProvider<Object> provider, {
  bool overBlack = false,
}) async {
  final stream = provider.resolve(ImageConfiguration.empty);
  final frame = Completer<ui.Image>();
  final listener = ImageStreamListener(
    (info, _) {
      frame.complete(info.image.clone());
      info.dispose();
    },
    onError: (Object error, StackTrace? trace) =>
        frame.completeError(error, trace),
  );
  stream.addListener(listener);
  try {
    final image = await frame.future;
    try {
      expect((image.width, image.height), (512, 512));
      if (!overBlack) return Uint8List.sublistView((await image.toByteData())!);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff000000), ui.BlendMode.src);
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      final picture = recorder.endRecording();
      try {
        final composite = await picture.toImage(image.width, image.height);
        try {
          return Uint8List.sublistView((await composite.toByteData())!);
        } finally {
          composite.dispose();
        }
      } finally {
        picture.dispose();
      }
    } finally {
      image.dispose();
    }
  } finally {
    stream.removeListener(listener);
    await provider.evict();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'translucent Mummy paper matches the studio over a black backdrop',
    () async {
      // Outer edge of the hand. Its master alpha is 118/255 at this location.
      const index = (384 * 512 + 120) * 4;
      for (final (tone, expected) in [
        (SkinTone.peach, [116, 82, 54]),
        (SkinTone.fair, [112, 93, 78]),
        (SkinTone.deepest, [62, 35, 25]),
      ]) {
        final art = await pixels(
          paperPortrait('assets/images/body-mummy.png', tone),
          overBlack: true,
        );
        for (var c = 0; c < 3; c++) {
          expect(art[index + c], closeTo(expected[c], 2), reason: tone.label);
        }
      }
    },
  );
  test(
    'the engine decodes every tint mask and preserves each registered silhouette',
    () async {
      for (final name in [
        'everyday',
        'body-vampire',
        'body-mummy',
        'body-witch',
        'body-ghost',
        'body-skeleton',
        'body-zombie',
      ]) {
        for (final expression in [
          '',
          '-happy',
          if (name == 'everyday') '-sleepy',
        ]) {
          final path = 'assets/images/$name$expression.png';
          printOnFailure("Rendering $path");
          final base = await pixels(paperPortrait(path, SkinTone.peach));
          for (final tone in SkinTone.values.where(
            (tone) => tone != SkinTone.peach,
          )) {
            printOnFailure("Rendering $path / ${tone.name}");
            final tinted = await pixels(paperPortrait(path, tone));
            var differentSkinPixels = 0;
            var alphaChanges = 0;
            for (var i = 0; i < base.length; i += 4) {
              if (base[i + 3] != tinted[i + 3]) alphaChanges++;
              if (base[i + 3] > 200 &&
                  (base[i + 1] - tinted[i + 1]).abs() > 4) {
                differentSkinPixels++;
              }
            }
            expect(alphaChanges, 0, reason: '$path with ${tone.label}');
            expect(differentSkinPixels, greaterThan(1000));
          }
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
