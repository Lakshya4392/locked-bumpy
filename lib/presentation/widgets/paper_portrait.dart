import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import '../../domain/models/skin_tone.dart';

/// Peach uses the original registered PNG. Flutter caches each alternate by
/// both the source path and tone, just as it caches an ordinary asset image.
ImageProvider<Object> paperPortrait(String path, SkinTone tone) =>
    tone == SkinTone.peach ? AssetImage(path) : PaperTintImage(path, tone);

@immutable
class PaperTintImage extends ImageProvider<PaperTintImage> {
  const PaperTintImage(this.path, this.tone);
  final String path;
  final SkinTone tone;

  @override
  Future<PaperTintImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    PaperTintImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_decode());

  static Future<ui.Image> _readAsset(String path) async {
    final bytes = await rootBundle.load(path);
    return decodeImageFromList(Uint8List.sublistView(bytes));
  }

  Future<ImageInfo> _decode() async {
    final maskPath = path
        .replaceFirst('assets/images/', 'assets/images/tint-')
        .replaceFirst(RegExp(r'\.png$'), '.webp');
    final master = await _readAsset(path);
    ui.Image? mask;
    try {
      mask = await _readAsset(maskPath);
      if (master.width != mask.width || master.height != mask.height) {
        throw StateError('Tint mask does not fit $path');
      }
      final art = await master.toByteData(format: ui.ImageByteFormat.rawRgba);
      final weights = await mask.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (art == null || weights == null) {
        throw StateError('Unreadable paper art: $path');
      }
      final pixels = Uint8List.sublistView(art);
      _tintPixels(pixels, Uint8List.sublistView(weights), tone);
      return await _frame(pixels, master.width, master.height);
    } finally {
      mask?.dispose();
      master.dispose();
    }
  }

  static Future<ImageInfo> _frame(
    Uint8List pixels,
    int width,
    int height,
  ) async {
    if (kIsWeb) {
      // The web ImageDescriptor encodes a BMP, which applies alpha a second
      // time to translucent paper. Send premultiplied pixels to CanvasKit directly.
      final frame = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixels,
        width,
        height,
        ui.PixelFormat.rgba8888,
        frame.complete,
      );
      return ImageInfo(image: await frame.future);
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      codec = await descriptor.instantiateCodec();
      return ImageInfo(image: (await codec.getNextFrame()).image);
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static void _tintPixels(Uint8List pixels, Uint8List mask, SkinTone tone) {
    const original = [250, 176, 115];
    const blush = [54, 26, 28];
    final target = [tone.rgb >> 16, (tone.rgb >> 8) & 255, tone.rgb & 255];
    final depth = ((200 - target.first) / 68).clamp(0.0, 1.0);
    for (var i = 0; i < pixels.length; i += 4) {
      final skin = mask[i] / 255;
      final cheek = mask[i + 1] * depth / 255;
      final alpha = pixels[i + 3] / 255;
      if (alpha == 0 || (skin == 0 && cheek == 0)) continue;
      for (var channel = 0; channel < 3; channel++) {
        // Flutter uses premultiplied pixels. Do the studio's paper and blush
        // adjustments in straight RGB and preserve the original alpha.
        final value = pixels[i + channel] / alpha;
        final paper = (target[channel] + .9 * (value - original[channel]))
            .clamp(0.0, 255.0);
        final result = value + skin * (paper - value) - cheek * blush[channel];
        pixels[i + channel] = (result.clamp(0.0, 255.0) * alpha).round();
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PaperTintImage && other.path == path && other.tone == tone;
  @override
  int get hashCode => Object.hash(path, tone);
}
