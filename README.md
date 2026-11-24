# Little Bumpy

Little Bumpy is a free, private pregnancy companion app narrated entirely by the unborn baby, built for the **Kiroween 2026 (Costume Contest)** hackathon.

In Halloween mode, each costume represents an essential maternal health need: the little vampire wants iron, the mummy asks for water, the skeleton loves calcium, and the witch reminds mom of her doctor-prescribed prenatal vitamin.

---

## Key Features
- **Narrated by Baby:** The baby speaks directly in first person ("you").
- **Two Modes, Complete Parity:** Switch between Everyday ("lamp on") and Halloween ("lamp off") with instant theme parity.
- **Kind & Pressure-Free:** No guilt streaks, no penalty for missed days. Only "Days Together", which strictly increases.
- **Safe & Private:** 100% on-device. Zero network requests, zero tracking, zero runtime AI, and zero ads.
- **Single-Tap Pause:** Instantly silences the app with compassionate app voice if mom needs a break.

---

## Open Source Disclosure
`harness/` is pre-existing open-source code (MIT) written for Karan's avatar harness and used with disclosure in accordance with Kiroween hackathon rules.

---

## Build & Test

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The native suite checks the art through the Flutter engine. The Linux CI job also
runs `python tool/test_web_portraits.py` in Chromium against the same 15 source
portraits at all five skin tones. The browser test stages its art temporarily
because Flutter's web test server omits app assets. On Windows, the same command
uses Python Playwright to serve the pinned local CanvasKit renderer to Chrome.
Install that test dependency once with `python -m pip install playwright`.

For an installable web release, run `python tool/prepare_offline_web.py --build`
and serve `build/web/` over HTTPS or localhost. The command uses the local
CanvasKit renderer and bundles the fonts, app shell, costumes and content for
offline use. Packaging verifies the bundled content and paper art against the
current checkout before writing the worker. For a site hosted below the root, run Flutter with the site's base
path first, then package that output:

```bash
flutter build web --release --no-web-resources-cdn --base-href /little-bumpy/
python tool/prepare_offline_web.py
```

To check a deployment, open it online once and wait for the service worker to
activate. Switch the browser offline, reload, and open a costume you haven't
viewed. Updates take effect after the existing app tabs close. A partial
download keeps the previous complete release available.
Serve the packaged bytes unchanged so the browser can verify their hashes.
