#!/usr/bin/env python3
"""Generate platform brand assets from Ripple's in-app vector geometry.

The paths and palette mirror AquaMascotPainter and AppColors. Run this script
from the repository root after intentionally changing either source.
"""

from __future__ import annotations

import io
from pathlib import Path

import cairosvg
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
NAVY = "#123047"
DEEP_WATER = "#126B78"
WATER = "#2E9EB0"
WATER_LIGHT = "#A9E0E4"
FOAM = "#F8FCFB"
WHITE = "#FFFFFF"
PEACH = "#F5B69B"
SAGE = "#78A98A"
SAGE_LIGHT = "#DDEBDD"


def ripple_markup() -> str:
    """Return a static, friendly Ripple pose in the painter's 200x232 space."""
    return f"""
      <defs>
        <linearGradient id="body" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="{FOAM}"/>
          <stop offset="0.28" stop-color="{WATER_LIGHT}"/>
          <stop offset="0.78" stop-color="{WATER}"/>
          <stop offset="1" stop-color="{DEEP_WATER}"/>
        </linearGradient>
        <linearGradient id="fin" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="{SAGE_LIGHT}"/>
          <stop offset="1" stop-color="{SAGE}"/>
        </linearGradient>
      </defs>
      <g stroke-linecap="round" stroke-linejoin="round">
        <path d="M49 137 C34 119 9 119 1 139 C19 154 37 153 49 137 Z"
              fill="url(#fin)" stroke="{DEEP_WATER}" stroke-width="3"/>
        <path d="M41 138 Q24 135 10 138" fill="none" stroke="{FOAM}"
              stroke-opacity=".72" stroke-width="2.5"/>
        <path d="M151 137 C166 119 191 119 199 139 C181 154 163 153 151 137 Z"
              fill="url(#fin)" stroke="{DEEP_WATER}" stroke-width="3"/>
        <path d="M159 138 Q176 135 190 138" fill="none" stroke="{FOAM}"
              stroke-opacity=".72" stroke-width="2.5"/>
        <path d="M100 16 C91 43 42 74 42 132 C42 178 67 207 100 207
                 C137 207 158 178 158 132 C158 75 111 43 100 16 Z"
              fill="url(#body)" stroke="{DEEP_WATER}" stroke-width="4"/>
        <ellipse cx="105" cy="166" rx="36" ry="28" fill="{FOAM}" fill-opacity=".28"/>
        <path d="M77 53 C60 75 54 101 55 122" fill="none" stroke="{WHITE}"
              stroke-opacity=".55" stroke-width="8"/>
        <path d="M69 87 C76 75 82 70 87 66" fill="none" stroke="{WHITE}"
              stroke-opacity=".24" stroke-width="3"/>
        <g fill="{FOAM}" stroke="{NAVY}" stroke-width="2.5">
          <ellipse cx="78" cy="124" rx="8.5" ry="7.5"/>
          <ellipse cx="122" cy="124" rx="8.5" ry="7.5"/>
        </g>
        <g fill="{NAVY}">
          <ellipse cx="78" cy="126" rx="4.2" ry="4.8"/>
          <ellipse cx="122" cy="126" rx="4.2" ry="4.8"/>
        </g>
        <g fill="{WHITE}">
          <circle cx="75.9" cy="123.4" r="1.65"/>
          <circle cx="119.9" cy="123.4" r="1.65"/>
        </g>
        <g fill="{PEACH}" fill-opacity=".45">
          <ellipse cx="67" cy="147" rx="8" ry="4"/>
          <ellipse cx="133" cy="147" rx="8" ry="4"/>
        </g>
        <path d="M84 153 Q100 160.7 116 153" fill="none" stroke="{NAVY}"
              stroke-width="4.5"/>
      </g>
    """


def svg_document(width: int, height: int, *, background: str | None,
                 round_background: bool = False, mascot_scale: float = 1.0) -> str:
    source_width = 200 * mascot_scale
    source_height = 232 * mascot_scale
    offset_x = (width - source_width) / 2
    offset_y = (height - source_height) / 2
    if background is None:
        background_markup = ""
    elif round_background:
        background_markup = (
            f'<circle cx="{width / 2}" cy="{height / 2}" r="{min(width, height) / 2}" '
            f'fill="{background}"/>'
        )
    else:
        background_markup = f'<rect width="{width}" height="{height}" fill="{background}"/>'
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}"
      viewBox="0 0 {width} {height}">
      {background_markup}
      <g transform="translate({offset_x} {offset_y}) scale({mascot_scale})">
        {ripple_markup()}
      </g>
    </svg>"""


def render(path: Path, width: int, height: int, *, background: str | None,
           round_background: bool = False, mascot_scale: float | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    # Ripple occupies at most 63% of either canvas dimension, safely inside the
    # 66% adaptive-icon foreground zone.
    scale = mascot_scale or min(width * 0.63 / 200, height * 0.63 / 232)
    oversample = max(1, 4 if min(width, height) <= 192 else 2)
    svg = svg_document(
        width * oversample,
        height * oversample,
        background=background,
        round_background=round_background,
        mascot_scale=scale * oversample,
    )
    png = cairosvg.svg2png(bytestring=svg.encode("utf-8"))
    with Image.open(io.BytesIO(png)) as image:
        image = image.convert("RGBA")
        if oversample > 1:
            image = image.resize((width, height), Image.Resampling.LANCZOS)
        if background is not None and not round_background:
            image = image.convert("RGB")
        image.save(path, optimize=True)


def generate_android() -> None:
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    base = ROOT / "android/app/src/main/res"
    for density, size in sizes.items():
        folder = base / f"mipmap-{density}"
        render(folder / "ic_launcher.png", size, size, background=NAVY)
        render(
            folder / "ic_launcher_round.png",
            size,
            size,
            background=NAVY,
            round_background=True,
        )
def generate_web() -> None:
    base = ROOT / "web"
    render(base / "favicon.png", 32, 32, background=NAVY)
    for size in (192, 512):
        render(base / f"icons/Icon-{size}.png", size, size, background=NAVY)
        render(base / f"icons/Icon-maskable-{size}.png", size, size, background=NAVY)


def generate_ios() -> None:
    base = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in sizes.items():
        render(base / filename, size, size, background=NAVY)

    launch_base = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for filename, scale in {
        "LaunchImage.png": 1,
        "LaunchImage@2x.png": 2,
        "LaunchImage@3x.png": 3,
    }.items():
        render(launch_base / filename, 168 * scale, 185 * scale, background=None)


def generate_macos() -> None:
    base = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        render(base / f"app_icon_{size}.png", size, size, background=NAVY)


if __name__ == "__main__":
    generate_android()
    generate_web()
    generate_ios()
    generate_macos()
