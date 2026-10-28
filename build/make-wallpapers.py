#!/usr/bin/env python3
"""Turn the Samurai art collection into desktop wallpapers and installer art.

The source art lives in ``Samurai Walls/`` (small JPEGs, 236-760 px). This
script produces 1920x1080 desktop wallpapers for the live session and for
systems installed from it, plus the 800x400 Calamares welcome slide:

  * landscape sources are scaled up and centre-cropped to 16:9,
  * portrait sources are placed, fit to full height, over a blurred copy of
    themselves so the art is never distorted or awkwardly cropped,
  * the Kuro (dark) and Shiro (light) themes each get a stable default
    wallpaper name that ``samurai-theme`` applies: kuro.jpg / shiro.jpg.

Outputs are committed to the repository, so ISO builds do not need Pillow.
Regenerate with:

    python3 build/make-wallpapers.py

Requires Pillow (``pip install pillow``).
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageFilter

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = REPO_ROOT / "Samurai Walls"
DEFAULT_OUT = (
    REPO_ROOT
    / "build"
    / "config"
    / "includes.chroot"
    / "usr"
    / "share"
    / "backgrounds"
    / "samurai"
)
DEFAULT_SLIDE = (
    REPO_ROOT
    / "build"
    / "config"
    / "includes.chroot"
    / "etc"
    / "calamares"
    / "branding"
    / "samurai"
    / "slide1.png"
)

WALLPAPER_SIZE = (1920, 1080)
SLIDE_SIZE = (800, 400)
QUALITY = 88

# Source file -> output name. The first two entries are the theme defaults
# that samurai-theme applies by name; the third is reused for the installer
# slide. Everything else becomes samurai-<slug>.jpg.
MAPPING = [
    ("images (16).jfif", "kuro.jpg"),
    ("images (8).jfif", "shiro.jpg"),
    ("images (2).jfif", "crimson-moon.jpg"),
    ("images (1).jfif", "forest-duel.jpg"),
    ("images (10).jfif", "moonlit-tree.jpg"),
    ("images (11).jfif", "torii-wave.jpg"),
    ("images (12).jfif", "moonlit-antlers.jpg"),
    ("images (13).jfif", "neon-city-rain.jpg"),
    ("images (14).jfif", "golden-ring.jpg"),
    ("images (15).jfif", "ember-blade.jpg"),
    ("images (17).jfif", "neon-violet.jpg"),
    ("images (18).jfif", "neon-triangle.jpg"),
    ("images (19).jfif", "glitch-cyan.jpg"),
    ("images (20).jfif", "staff-keeper.jpg"),
    ("images (21).jfif", "glitch-katana.jpg"),
    ("images (3).jfif", "sunset-roof.jpg"),
    ("images (4).jfif", "crimson-duel.jpg"),
    ("images (5).jfif", "misty-forest.jpg"),
    ("images (6).jfif", "ink-leap.jpg"),
    ("images (7).jfif", "golden-hour-duel.jpg"),
    ("images (9).jfif", "crimson-faces.jpg"),
    ("images.jfif", "torii-duel.jpg"),
]
SLIDE_SOURCE = "images (2).jfif"


def cover_crop(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Scale ``image`` up until it covers ``size``, then centre-crop."""
    target_w, target_h = size
    src_w, src_h = image.size
    scale = max(target_w / src_w, target_h / src_h)
    resized = image.resize(
        (max(target_w, round(src_w * scale)), max(target_h, round(src_h * scale))),
        Image.LANCZOS,
    )
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def make_wallpaper(source: Path, size: tuple[int, int]) -> Image.Image:
    with Image.open(source) as im:
        image = im.convert("RGB")

    src_w, src_h = image.size
    target_w, target_h = size
    if src_w / src_h >= target_w / target_h:
        return cover_crop(image, size)

    # Portrait art: keep the whole composition by fitting it to the full
    # height over a blurred, slightly darkened copy of the same picture.
    scale = target_h / src_h
    foreground = image.resize((round(src_w * scale), target_h), Image.LANCZOS)
    background = cover_crop(image, size).filter(ImageFilter.GaussianBlur(48))
    background = Image.eval(background, lambda px: int(px * 0.65))
    background.paste(foreground, ((target_w - foreground.width) // 2, 0))
    return background


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--slide", type=Path, default=DEFAULT_SLIDE)
    args = parser.parse_args()

    if not args.source.is_dir():
        parser.error(f"source directory not found: {args.source}")

    args.out.mkdir(parents=True, exist_ok=True)

    written = []
    for name, output in MAPPING:
        source = args.source / name
        if not source.is_file():
            parser.error(f"missing source image: {source}")
        wallpaper = make_wallpaper(source, WALLPAPER_SIZE)
        target = args.out / output
        wallpaper.save(target, "JPEG", quality=QUALITY, optimize=True)
        written.append(target)

    slide = make_wallpaper(args.source / SLIDE_SOURCE, SLIDE_SIZE)
    args.slide.parent.mkdir(parents=True, exist_ok=True)
    slide.convert("RGBA").save(args.slide, "PNG", optimize=True)
    written.append(args.slide)

    for path in written:
        print(f"{path.relative_to(REPO_ROOT)} {path.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
