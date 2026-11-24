# Asset Inventory

Graphical assets and fonts used in Little Bumpy.

| Asset | Source / Creator | License / Status | Date |
|---|---|---|---|
| `harness/` | Pre-existing open-source code | MIT | 2026-11-22 |
| Fraunces | Google Fonts | Open Font License | 2026-11-22 |
| Atkinson Hyperlegible | Braille Institute | Open Font License | 2026-11-22 |
| `assets/images/everyday.png`, `everyday-happy.png`, `everyday-sleepy.png` | Bumpy Studio, Everyday lavender paper-cut pose | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-vampire.png`, `body-vampire-happy.png` | Bumpy Studio, Violet Vampire (Iron) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-mummy.png`, `body-mummy-happy.png` | Bumpy Studio, Mummy (Water) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-witch.png`, `body-witch-happy.png` | Bumpy Studio, Witch (Vitamin) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-ghost.png`, `body-ghost-happy.png` | Bumpy Studio, Ghost (Rest) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-skeleton.png`, `body-skeleton-happy.png` | Bumpy Studio, Skeleton (Bones) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-zombie.png`, `body-zombie-happy.png` | Bumpy Studio, Zombie (Brain) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/need-{iron,water,vitamin,rest,bones,brain}.png` | Bumpy Studio, registered icons in `pieces/need/` | Team Kit Studio Release | 2026-11-23 |
| `assets/images/nursery-lamp.png` | Bumpy Studio, `originals/nursery-lamp.png` | Team Kit Studio Release | 2026-11-23 |
| `assets/images/nursery-everyday.png` | Bumpy Studio, `originals/everyday-nursery.png` | Team Kit Studio Release | 2026-11-23 |
| `assets/images/nursery-halloween.png` | Bumpy Studio, `originals/night-nursery-violet.png` | Team Kit Studio Release | 2026-11-23 |

The full-character PNGs use the Demo Starter poses and the Peach tone from the studio rig with its `reference-paper-v4` expression recipe. The base expression is Calm. Happy uses Wide smile, with First tooth for Vampire. The sprites keep the studio's common canvas and face placement at 512 × 512 pixels. Icons and backdrops preserve their source proportions at a 512-pixel long edge.

## Five studio skin tones

The app keeps the 24 original PNGs and adds 15 lossless WebP masks (214,824 bytes). The masks carry skin and blush weights for the seven looks and their expressions. Flutter applies the studio colours to the original 512 px paper art on the device. The complete image folder is 3,920,345 bytes. The original Peach PNG renders directly.

To regenerate the masks, use Python with Pillow and NumPy and run `python tool/make_paper_tones.py /path/to/avatar-harness`. Add `--check` to compare the export with the committed masks. The exporter compares all 60 alternate renders with the studio rig at 190 px and checks their full-resolution alpha channels.
