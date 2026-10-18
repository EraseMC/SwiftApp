"""Copies the site's artwork into the app's asset catalogue.

Usage: python tools/sync_web_assets.py [path/to/Imprint-Web]

Mode icons, item textures, hearts and arena backgrounds are owned by Imprint-Web
(`public/`). Rerun this after they change there; the output is committed.
"""

import json
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
WEB = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT.parent / "Imprint-Web"
CATALOGUE = ROOT / "App" / "Resources" / "Assets.xcassets"

INFO = {"author": "xcode", "version": 1}


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def namespace(name: str) -> Path:
    """A folder whose name prefixes its images: `Modes/no_debuff` is looked up as `modes/no_debuff`."""
    folder = CATALOGUE / name
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    write_json(folder / "Contents.json", {"info": INFO, "properties": {"provides-namespace": True}})
    return folder


def imageset(folder: Path, name: str, source: Path, pixel_art: bool) -> None:
    target = folder / f"{name}.imageset"
    target.mkdir()

    if source.suffix.lower() == ".webp":
        # Asset catalogues do not compile WebP; photos go in as high-quality JPEG.
        filename = f"{name}.jpg"
        Image.open(source).convert("RGB").save(target / filename, quality=90)
    else:
        filename = f"{name}{source.suffix.lower()}"
        shutil.copyfile(source, target / filename)

    properties = {"preserves-vector-representation": False}
    if pixel_art:
        # Keeps Minecraft textures crisp when the catalogue builds thumbnails.
        properties["compression-type"] = "lossless"

    write_json(target / "Contents.json", {
        "images": [{"idiom": "universal", "filename": filename}],
        "info": INFO,
        "properties": properties,
    })


def sync(folder_name: str, source_dir: Path, pattern: str, pixel_art: bool) -> int:
    folder = namespace(folder_name)
    count = 0
    for source in sorted(source_dir.glob(pattern)):
        imageset(folder, source.stem, source, pixel_art)
        count += 1
    return count


def main() -> None:
    public = WEB / "public"
    if not public.is_dir():
        sys.exit(f"Imprint-Web not found at {WEB}")

    print("modes", sync("Modes", public / "icons" / "modes", "*.png", pixel_art=True))
    print("items", sync("Items", public / "items", "*.png", pixel_art=True))
    print("ui", sync("UI", public / "ui", "*.png", pixel_art=True))
    print("arena", sync("Arena", public / "assets" / "arena", "*.webp", pixel_art=False))


if __name__ == "__main__":
    main()
