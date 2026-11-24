"""Run the browser portrait test with the real studio PNGs and masks."""
import base64
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]

# Flutter's web test host serves the test program but omits application assets.
# Register the same bytes on its test asset channel without running an app build.
WRAPPER = """import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'widget/paper_portrait_test.dart' as portraits;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (data) async {
      final key = utf8.decode(Uint8List.sublistView(data!));
      if (key == 'AssetManifest.bin.json') {
        final manifest = {for (final name in art.keys) name: [{'asset': name}]};
        final binary = const StandardMessageCodec().encodeMessage(manifest)!;
        final json = jsonEncode(base64Encode(Uint8List.sublistView(binary)));
        return ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));
      }
      final bytes = art[key];
      if (bytes == null) throw StateError('Missing test art $key');
      return ByteData.sublistView(base64Decode(bytes));
    });
  });
  portraits.main();
}

const art = <String, String>{
"""


def main():
    flutter = shutil.which("flutter")
    if not flutter:
        raise SystemExit("Flutter is missing from PATH.")
    images = ROOT / "assets/images"
    with tempfile.NamedTemporaryFile(dir=ROOT / "test", prefix="local_paper_", suffix="_test.dart",
                                     mode="w", encoding="utf-8", delete=False) as file:
        entry = Path(file.name)
    try:
        with entry.open("w", encoding="utf-8") as file:
            file.write(WRAPPER)
            for mask in sorted(images.glob("tint-*.webp")):
                master = mask.with_name(mask.stem.removeprefix("tint-") + ".png")
                for path in [master, mask]:
                    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
                    file.write(f"  '{path.relative_to(ROOT).as_posix()}': '{encoded}',\n")
            file.write("};\n")
        command = [
            flutter, "test", "--no-pub", "--platform", "chrome",
            entry.relative_to(ROOT).as_posix(), "--reporter=expanded",
        ]
        if sys.platform == "win32":
            from windows_chrome_test import run
            return run(command, ROOT)
        return subprocess.run(command, cwd=ROOT).returncode
    finally:
        entry.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
