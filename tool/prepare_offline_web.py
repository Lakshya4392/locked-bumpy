"""Package the built Flutter site for same-origin, offline use."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[1]
WORKER = "bumpy-offline.js"
POLICY = '<meta http-equiv="Content-Security-Policy" content="default-src \'self\'; script-src \'self\' \'wasm-unsafe-eval\' blob:; style-src \'self\' \'unsafe-inline\'; img-src \'self\' data: blob:; font-src \'self\' data:; connect-src \'self\' blob:; worker-src \'self\' blob:; object-src \'none\'; base-uri \'self\'; form-action \'none\'">'
REGISTER = """
if ("serviceWorker" in navigator && window.isSecureContext) {
  navigator.serviceWorker.register(new URL("bumpy-offline.js", document.baseURI))
    .catch((error) => console.warn("Offline installation did not finish.", error));
}
"""
# Only files shipped by Flutter and this app belong in the offline cache.
ASSET_DIRS = {"assets", "canvaskit", "fonts", "icons"}
SHELL_FILES = {"index.html", "flutter_bootstrap.js", "flutter.js", "main.dart.js",
               "main.dart.mjs", "main.dart.wasm", "manifest.json", "version.json", "favicon.png"}


def package(root):
    bootstrap = root / "flutter_bootstrap.js"
    required = {"index.html", "flutter_bootstrap.js", "manifest.json"}
    for prefix in ["canvaskit/", "canvaskit/chromium/"]:
        required.update(prefix + name for name in ["canvaskit.js", "canvaskit.wasm"])
    bundled = {"assets/" + source.relative_to(ROOT).as_posix(): source
               for source in (ROOT / "assets").rglob("*") if source.is_file()}
    required.update(bundled)
    for font in (ROOT / "web/fonts").rglob("*.woff2"):
        required.add(font.relative_to(ROOT / "web").as_posix())
    manifest = json.loads((ROOT / "web/manifest.json").read_text(encoding="utf-8"))
    required.update(icon["src"] for icon in manifest["icons"])
    missing = sorted(name for name in required if not (root / name).is_file())
    if missing:
        raise SystemExit("Incomplete offline release. Missing " + ", ".join(missing))
    stale = [name for name, source in bundled.items() if (root / name).read_bytes() != source.read_bytes()]
    if stale:
        raise SystemExit("Rebuild before packaging. Bundled files differ from this checkout: " + ", ".join(sorted(stale)))
    if not any((root / name).is_file() for name in ["main.dart.js", "main.dart.wasm"]):
        raise SystemExit("Missing the compiled app entry point.")
    # Development's Dart debugger needs capabilities the release site does not.
    index = root / "index.html"
    html = index.read_text(encoding="utf-8")
    if POLICY not in html:
        if "<head>" not in html:
            raise SystemExit("Missing <head> in the web entry page.")
        index.write_bytes(html.replace("<head>", "<head>\n  " + POLICY, 1).encode("utf-8"))
    script = bootstrap.read_text(encoding="utf-8")
    if REGISTER.strip() not in script:
        bootstrap.write_bytes((script.rstrip() + "\n" + REGISTER).encode("utf-8"))

    assets = {}
    total = 0
    for path in sorted(root.rglob("*")):
        rel = path.relative_to(root)
        if not path.is_file() or any(part.startswith(".") for part in rel.parts):
            continue
        if rel.as_posix() not in SHELL_FILES and rel.parts[0] not in ASSET_DIRS:
            continue
        if path.suffix in {".map", ".symbols"}:
            continue
        if rel.parts[0] == "canvaskit" and path.name.startswith("skwasm") and not (root / "main.dart.wasm").is_file():
            continue
        data = path.read_bytes()
        assets[rel.as_posix()] = "sha256-" + base64.b64encode(hashlib.sha256(data).digest()).decode("ascii")
        total += len(data)
    entries = json.dumps(assets, sort_keys=True, ensure_ascii=True, separators=(",", ":"))
    template = Path(__file__).with_name("offline_worker.js").read_text(encoding="utf-8")
    version = hashlib.sha256((entries + template).encode("utf-8")).hexdigest()[:24]
    source = template.replace("__ASSET_DIGESTS__", entries).replace("__RELEASE__", json.dumps(version))
    (root / WORKER).write_bytes(source.encode("utf-8"))
    print(f"Offline release {version}: {len(assets)} files, {total:,} bytes")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true", help="Run the pinned project's Flutter release build first")
    parser.add_argument("--output", type=Path, default=ROOT / "build" / "web")
    args = parser.parse_args()
    output = args.output.resolve()
    if args.build:
        flutter = shutil.which("flutter")
        if flutter is None:
            raise SystemExit("Flutter is missing from PATH.")
        subprocess.run([flutter, "build", "web", "--release", "--no-web-resources-cdn",
                        "--output", str(output)], cwd=ROOT, check=True)
    package(output)


if __name__ == "__main__":
    main()
