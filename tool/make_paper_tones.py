"""Export small tint masks from the Bumpy studio rig. Requires Pillow and NumPy."""
import argparse
import io
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image

IMAGES = Path(__file__).resolve().parents[1] / "assets" / "images"
POSES = {
    "everyday": "everyday-papercut", "body-vampire": "vampire-violet",
    **{"body-" + name: name for name in ("mummy", "witch", "ghost", "skeleton", "zombie")},
}
BASE = np.array((250, 176, 115), dtype=np.float32)
BLUSH = np.array((54, 26, 28), dtype=np.float32)
PAPER_SCALE = 0.9


def fit_masks(studio_frames, colors, master):
    """Fit a skin and a cheek weight per pixel to all four studio references."""
    base = np.asarray(master, dtype=np.float32)[:, :, :3]
    skin_deltas, cheek_deltas, reference_deltas = [], [], []
    for frame, color in zip(studio_frames, colors):
        if frame.getchannel("A").tobytes() != master.getchannel("A").tobytes():
            raise ValueError("Studio tint changed the silhouette.")
        skin_deltas.append(np.clip(color + PAPER_SCALE * (base - BASE), 0, 255) - base)
        cheek_deltas.extend(-BLUSH * np.clip((200 - color[0]) / 68, 0, 1))
        reference_deltas.append(np.asarray(frame, dtype=np.float32)[:, :, :3] - base)

    # The two-column least-squares system counts the contribution of each
    # painted layer even at an antialiased boundary between skin and fabric.
    skin = np.concatenate(skin_deltas, axis=2)
    cheek = np.array(cheek_deltas)
    reference = np.concatenate(reference_deltas, axis=2)
    ss = (skin * skin).sum(2)
    sc = (skin * cheek).sum(2)
    cc = (cheek * cheek).sum()
    sr = (skin * reference).sum(2)
    cr = (cheek * reference).sum(2)
    determinant = np.maximum(ss * cc - sc * sc, 1)
    weights = np.stack(((sr * cc - cr * sc) / determinant,
                        (cr * ss - sr * sc) / determinant, np.zeros_like(sr)), axis=2)
    # Six bits per weight keeps the paper bundle inside the 4 MB limit.
    mask = np.rint(np.rint(np.clip(weights, 0, 1) * 63) * (255 / 63)).astype(np.uint8)
    mask[np.asarray(master)[:, :, 3] == 0] = 0

    for index, original in enumerate(studio_frames):
        delta = (skin_deltas[index] * mask[:, :, :1] / 255 +
                 cheek[3 * index:3 * index + 3] * mask[:, :, 1:2] / 255)
        rgb = np.clip(np.rint(base + delta), 0, 255).astype(np.uint8)
        rebuilt = Image.fromarray(rgb)
        rebuilt.putalpha(master.getchannel("A"))
        def phone(im):
            return np.asarray(im.resize((190, 190), Image.Resampling.LANCZOS).convert("RGBa"), dtype=np.int16)
        error = int(np.abs(phone(original) - phone(rebuilt)).max())
        if error > 8:
            raise ValueError(f"Phone rendering drifted by {error} channel levels.")
    return Image.fromarray(mask)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("harness", type=Path, help="Checkout of DoctorFlow/avatar-harness")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    sys.path.insert(0, str(args.harness.resolve() / "tools"))
    from bumpy_rig import compose
    rig = args.harness / "studio/chatgpt/rig/manifest.json"
    registry = json.loads(rig.read_text(encoding="utf-8"))
    tones = [tone for tone in registry["tones"] if tone["id"] != "peach"]
    from PIL import ImageColor
    colors = [np.array(ImageColor.getrgb(tone["color"])) for tone in tones]
    masks = {}
    for stem, pose in POSES.items():
        faces = {"": "calm", "-happy": "tooth" if stem == "body-vampire" else "wide-smile"}
        if stem == "everyday":
            faces["-sleepy"] = "sleepy"
        for suffix, face in faces.items():
            name = stem + suffix
            master = Image.open(IMAGES / (name + ".png")).convert("RGBA")
            def render(tone):
                return compose(rig, pose, tone, face).resize(master.size, Image.Resampling.LANCZOS)
            if render("peach").tobytes() != master.tobytes():
                raise ValueError(f"{name} no longer matches the studio master.")
            references = [render(tone["id"]) for tone in tones]
            mask = fit_masks(references, colors, master)
            encoded = io.BytesIO()
            mask.save(encoded, "WEBP", lossless=True, exact=True, method=6)
            masks[IMAGES / ("tint-" + name + ".webp")] = encoded.getvalue()

    existing = sum(p.stat().st_size for p in IMAGES.iterdir() if p.is_file() and p not in masks)
    total = existing + sum(len(data) for data in masks.values())
    if total >= 4_000_000:
        raise ValueError(f"Paper art exceeds budget: {total:,} bytes.")
    for path, data in masks.items():
        if args.check:
            if not path.exists() or path.read_bytes() != data:
                raise ValueError(f"Mask changed: {path.name}")
        else:
            path.write_bytes(data)
    print(f"{len(masks)} masks, {len(masks) * len(tones)} studio comparisons, {total:,} bytes of app art.")


if __name__ == "__main__":
    main()
