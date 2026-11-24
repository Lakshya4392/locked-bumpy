"""Tests the offline packaging step without running a Flutter build."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class PackageTest(unittest.TestCase):
    def test_installed_web_app_accepts_the_device_orientation(self):
        manifest = json.loads((Path(__file__).resolve().parents[1] / "web/manifest.json").read_text())
        self.assertEqual(manifest.get("orientation", "any"), "any")

    def test_missing_app_files_prevent_offline_installation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_output(root)
            paths = ["assets/assets/images/body-witch.png", "assets/assets/content/guide_articles.json",
                     "icons/Icon-192.png", "canvaskit/chromium/canvaskit.js"]
            paths.append(next(root.glob("assets/assets/images/*.webp")).relative_to(root).as_posix())
            paths.append(next(root.glob("fonts/**/*.woff2")).relative_to(root).as_posix())
            for path in paths:
                with self.subTest(path=path):
                    file = root / path
                    data = file.read_bytes()
                    file.unlink()
                    result = self.run_tool(root, check=False)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(path, result.stderr)
                    self.assertNotIn("Content-Security-Policy", (root / "index.html").read_text())
                    self.assertFalse((root / "bumpy-offline.js").exists())
                    file.write_bytes(data)

    def test_stale_reviewed_copy_or_art_cannot_be_published(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_output(root)
            for rel in ["assets/assets/content/today_lines.json", "assets/assets/images/body-witch.png"]:
                with self.subTest(rel=rel):
                    artifact = root / rel
                    current = artifact.read_bytes()
                    artifact.write_bytes(b"earlier build")
                    result = self.run_tool(root, check=False)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(rel, result.stderr)
                    self.assertFalse((root / "bumpy-offline.js").exists())
                    artifact.write_bytes(current)

    def test_app_art_stays_within_the_four_megabyte_demo_budget(self):
        images = Path(__file__).resolve().parents[1] / "assets/images"
        size = sum(p.stat().st_size for p in images.rglob("*") if p.is_file())
        self.assertLess(size, 4_000_000, f"App art totals {size:,} bytes")

    @staticmethod
    def make_output(root):
        project = Path(__file__).resolve().parents[1]
        names = ["index.html", "flutter_bootstrap.js", "main.dart.js"]
        names += [root_dir + filename for root_dir in ("canvaskit/", "canvaskit/chromium/")
                  for filename in ("canvaskit.js", "canvaskit.wasm")]
        names += ["assets/" + p.relative_to(project).as_posix()
                  for p in (project / "assets").rglob("*") if p.is_file()]
        names += [p.relative_to(project / "web").as_posix()
                  for p in (project / "web/fonts").rglob("*") if p.is_file()]
        manifest = (project / "web/manifest.json").read_text()
        names += [icon["src"] for icon in json.loads(manifest)["icons"]]
        for name in names:
            file = root / name
            file.parent.mkdir(parents=True, exist_ok=True)
            source = project / name.removeprefix("assets/")
            file.write_bytes(source.read_bytes() if name.startswith("assets/assets/") else name.encode())
        (root / "manifest.json").write_text(manifest)
        (root / "index.html").write_text("<html><head></head><body></body></html>")

    @staticmethod
    def run_tool(root, check=True):
        return subprocess.run([sys.executable, str(Path(__file__).with_name("prepare_offline_web.py")),
                               "--output", str(root)], check=check, capture_output=True, text=True)

    def test_repeated_packaging_keeps_one_registration_and_changes_with_assets(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_output(root)
            def package():
                self.run_tool(root)
                return (root / "bumpy-offline.js").read_bytes()
            first = package()
            self.assertEqual(first, package())
            self.assertEqual((root / "flutter_bootstrap.js").read_text().count('bumpy-offline.js'), 1)
            self.assertEqual((root / "index.html").read_text().count("Content-Security-Policy"), 1)
            self.assertIn(b'assets/assets/images/body-witch.png', first)
            (root / "version.json").write_text('{"version":"2"}')
            self.assertNotEqual(first, package())


if __name__ == "__main__":
    unittest.main()
