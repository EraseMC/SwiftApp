"""Builds the app icon variants from the site logo's lime "e" mark.

Usage: python tools/make_icons.py [path/to/erase-logo.jpg]

Writes the iOS 18 dark and tinted appearances of the primary icon and the
alternate icons into App/Resources/Assets.xcassets. The output is committed.
"""

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
LOGO = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Imprint-Web" / "public" / "assets" / "erase-logo.jpg"
CATALOGUE = ROOT / "App" / "Resources" / "Assets.xcassets"
SIZE = 1024
LIME = (168, 240, 56)
INK = (9, 12, 9)


def mark() -> Image.Image:
    """The "e" alone as a smooth 8-bit mask, cropped to its bounds."""
    pixels = np.asarray(Image.open(LOGO).convert("RGB")).astype(float)
    r, g, b = pixels[..., 0], pixels[..., 1], pixels[..., 2]
    # A continuous "how lime" field thresholds into a far smoother outline than a binary mask:
    # the glow around the mark falls off gradually, while JPEG noise mostly cancels out in the blur.
    field = np.clip((g - b - 70) / 110, 0, 1) * (r > 90)
    field[440:, :] = 0  # drop the small ERASE wordmark under the mark
    ys, xs = np.where(field > 0.5)
    box = (xs.min() - 12, ys.min() - 12, xs.max() + 13, ys.max() + 13)
    crop = Image.fromarray((field * 255).astype("uint8")).crop(box)
    big = crop.resize((crop.width * 8, crop.height * 8), Image.BICUBIC).filter(ImageFilter.GaussianBlur(18))
    big = big.point(lambda v: 255 if v > 128 else 0)
    return big.resize((crop.width * 4, crop.height * 4), Image.LANCZOS)


def place(mask: Image.Image, scale: float) -> Image.Image:
    """The mask centred on a 1024 canvas, its larger side `scale` of the icon."""
    side = int(SIZE * scale)
    ratio = side / max(mask.size)
    sized = mask.resize((int(mask.width * ratio), int(mask.height * ratio)), Image.LANCZOS)
    canvas = Image.new("L", (SIZE, SIZE), 0)
    canvas.paste(sized, ((SIZE - sized.width) // 2, (SIZE - sized.height) // 2))
    return canvas


def glow_background(base, glow, strength) -> Image.Image:
    background = Image.new("RGB", (SIZE, SIZE), base)
    halo = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(halo).ellipse((212, 212, 812, 812), fill=strength)
    halo = halo.filter(ImageFilter.GaussianBlur(160))
    return Image.composite(Image.new("RGB", (SIZE, SIZE), glow), background, halo)


def save(image: Image.Image, folder: str, filename: str) -> None:
    target = CATALOGUE / folder
    target.mkdir(parents=True, exist_ok=True)
    image.save(target / filename)


def main() -> None:
    shape = place(mark(), 0.56)

    # iOS 18 dark appearance: the mark on a transparent ground, the system adds the dark backdrop.
    dark = Image.new("RGBA", (SIZE, SIZE), (*LIME, 0))
    dark.putalpha(shape)
    save(dark, "AppIcon.appiconset", "AppIcon-Dark.png")

    # Tinted appearance: a grayscale mark the system colours with the user's tint.
    tinted = Image.merge("RGB", (shape, shape, shape))
    save(tinted, "AppIcon.appiconset", "AppIcon-Tinted.png")

    midnight = glow_background(INK, (40, 70, 14), 140)
    midnight.paste(Image.new("RGB", (SIZE, SIZE), LIME), mask=shape)
    save(midnight, "AppIcon-Midnight.appiconset", "AppIcon-Midnight.png")

    lime = glow_background(LIME, (196, 255, 110), 120)
    lime.paste(Image.new("RGB", (SIZE, SIZE), INK), mask=shape)
    save(lime, "AppIcon-Lime.appiconset", "AppIcon-Lime.png")

    write_contents()


def write_contents() -> None:
    info = {"author": "xcode", "version": 1}
    primary = {
        "images": [
            {"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "AppIcon-Dark.png",
             "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "tinted"}], "filename": "AppIcon-Tinted.png",
             "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        ],
        "info": info,
    }
    (CATALOGUE / "AppIcon.appiconset" / "Contents.json").write_text(json.dumps(primary, indent=2) + "\n")
    for name in ("Midnight", "Lime"):
        contents = {"images": [{"filename": f"AppIcon-{name}.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": info}
        (CATALOGUE / f"AppIcon-{name}.appiconset" / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    # Previews for the in-app icon picker; alternate app icons cannot be loaded as images at runtime.
    for name in ("Midnight", "Lime"):
        preview = CATALOGUE / "IconPreviews" / f"{name}.imageset"
        preview.mkdir(parents=True, exist_ok=True)
        Image.open(CATALOGUE / f"AppIcon-{name}.appiconset" / f"AppIcon-{name}.png").resize((180, 180), Image.LANCZOS).save(preview / f"{name}.png")
        (preview / "Contents.json").write_text(json.dumps({"images": [{"filename": f"{name}.png", "idiom": "universal"}], "info": info}, indent=2) + "\n")
    classic = CATALOGUE / "IconPreviews" / "Classic.imageset"
    classic.mkdir(parents=True, exist_ok=True)
    Image.open(CATALOGUE / "AppIcon.appiconset" / "AppIcon.png").resize((180, 180), Image.LANCZOS).save(classic / "Classic.png")
    (classic / "Contents.json").write_text(json.dumps({"images": [{"filename": "Classic.png", "idiom": "universal"}], "info": info}, indent=2) + "\n")
    folder = CATALOGUE / "IconPreviews" / "Contents.json"
    folder.write_text(json.dumps({"info": info, "properties": {"provides-namespace": True}}, indent=2) + "\n")


if __name__ == "__main__":
    main()
