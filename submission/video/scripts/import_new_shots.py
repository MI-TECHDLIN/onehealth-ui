#!/usr/bin/env python3
"""Copies the captain's new-app screenshots into screens/new/ under shot names.

The captain's phone screenshots (Android, 720 px wide) are read from
OAH_CAPTAIN_DIR (default /workspaces/firstmate/data/oah-video/) and written as
plain RGB PNGs (the phone's eXIf chunk trips ffmpeg). Two edits only: a solid,
irreversible bar over the account email in the sign-in screenshot, and removal
of the phone's own "show taps" indicators (translucent grey dots, not app
content). The six README stills are copied alongside. Run once when new screenshots arrive:

    python3 scripts/import_new_shots.py
"""
import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

SOURCE = Path(os.environ.get('OAH_CAPTAIN_DIR', '/workspaces/firstmate/data/oah-video'))
SCREENS = Path(__file__).resolve().parent.parent / 'screens'

# Shot name -> captain's file. Shot names follow the shot list (01a, 04b, ...).
SHOTS = {
    '01a': 'Screenshot_20261005-113040.png',  # onboarding 1: city health
    '02a': 'Screenshot_20261005-113051.png',  # onboarding 2: One Health
    '02b': 'Screenshot_20261005-113056.png',  # onboarding 3: look, photograph, answer
    '02c': 'Screenshot_20261005-113058.png',  # onboarding 4: safety reminder
    '02d': 'Screenshot_20261005-113101.png',  # onboarding 5: ready when you are
    '03a': 'Screenshot_20261005-113128.png',  # language picker
    '04a': 'Screenshot_20261005-113209.png',  # sign-in friendly error (email covered)
    '04b': 'Screenshot_20261005-113459.png',  # avatar picker
    '05a': 'Screenshot_20261005-113439.png',  # map with pin preview
    '05b': 'IMG_20261005_113304.png',         # which stream?
    '06a': 'Screenshot_20261005-113336.png',  # dams: Yes / No / I'm not sure
    '06b': 'Screenshot_20261005-113340.png',  # water height
    '08a': 'Screenshot_20261005-113344.png',  # overall health
    '09a': 'Screenshot_20261005-113353.png',  # photograph the stream
    '11a': 'Screenshot_20261005-113425.png',  # stream check submitted
    '13a': 'IMG_20261005_113239.png',         # profile: rhythm and badges
}

# Solid bars in source pixels: the "Username or email" value on the sign-in screen.
REDACTIONS = {
    '04a': [(120, 1014, 560, 1064)],
}

# Android "show taps" dots in source pixels: (x, y) is an approximate centre
# whose exact centre and fade remove_tap_dot finds; (x, y, fade) is exact, set
# by eye where text or a button edge under the dot misleads the search.
TAP_DOTS = {
    '02a': [(256, 1367), (471, 1307), (242, 1424, 0.5)],
    '02b': [(295, 1288), (500, 1296), (235, 1329)],
    '02c': [(296, 1095), (561, 1096), (284, 1325)],
    '02d': [(339, 1203), (600, 1161), (274, 1414, 0.9)],
    '03a': [(320, 1452), (538, 1472), (235, 1603, 0.9)],
    '04a': [(292, 1163), (500, 1188), (215, 1397)],
    '04b': [(354, 1154), (579, 1168), (225, 1404)],
    '05a': [(467, 956), (217, 1067), (176, 1289)],
    '05b': [(251, 1117), (514, 1102), (171, 1357)],
    '06a': [(262, 1138), (484, 1165), (188, 1365)],
    '06b': [(295, 1326), (530, 1251), (203, 1388)],
    '08a': [(290, 1329), (535, 1433, 0.5), (166, 1478, 0.35)],
    '09a': [(384, 973), (611, 1004), (272, 1218)],
    '11a': [(295, 1060, 1.0), (490, 1081), (233, 1306)],
    '13a': [(232, 1140), (472, 1089), (200, 1310)],
}
# The indicator itself, measured from these screenshots (a white-background and a
# teal-button dot at full strength): RGB = overlay colour, A = its opacity.
SPRITE = np.asarray(Image.open(Path(__file__).with_name('tap-dot-sprite.png')), dtype=np.float64)
SPRITE_A = SPRITE[..., 3:] / 255
SPRITE_P = SPRITE[..., :3] * SPRITE_A  # premultiplied colour
R = SPRITE.shape[0] // 2


def _unblend(window: np.ndarray, alpha: np.ndarray, premultiplied: np.ndarray, fade: float) -> tuple[np.ndarray, np.ndarray]:
    clean = (window - fade * premultiplied) / np.maximum(1 - fade * alpha, 0.05)
    # The thin ring is nearly opaque, so what lies beneath it is lost.
    return clean, (fade * alpha[..., 0]) > 0.8


_RADIUS = np.hypot(*np.mgrid[-R:R + 1, -R:R + 1]).astype(int)


def _leftover(clean: np.ndarray, opaque: np.ndarray, radius: np.ndarray) -> float:
    """How much circular structure remains: a leftover dot changes the mean
    colour from one radius to the next, while app content averages out."""
    usable = ~opaque
    means = []
    for r in range(2, R):
        ring = usable & (radius == r)
        if ring.sum() >= 4:
            means.append(clean[ring].mean(axis=0))
    return float(np.abs(np.diff(np.array(means), axis=0)).sum()) if len(means) > 1 else float('inf')


def _find_centre(a: np.ndarray, x0: int, y0: int) -> tuple[int, int]:
    """The dot's ring is its bluest part: pick the offset where the sprite's
    ring is much bluer than the grey disc inside it."""
    blue = a[..., 2] - (a[..., 0] + a[..., 1]) / 2
    ring, disc = SPRITE_A[..., 0] > 0.8, (SPRITE_A[..., 0] > 0.6) & (SPRITE_A[..., 0] < 0.75)
    h, w = blue.shape
    best = None
    for cy in range(max(R, y0 - 12), min(h - R, y0 + 13)):
        for cx in range(max(R, x0 - 12), min(w - R, x0 + 13)):
            window = blue[cy - R:cy + R + 1, cx - R:cx + R + 1]
            score = window[ring].mean() - window[disc].mean()
            if best is None or score > best[0]:
                best = (score, cx, cy)
    if best is None:  # dot cut off by the screen edge: keep the given centre
        return x0, y0
    return best[1], best[2]


def remove_tap_dot(a: np.ndarray, x0: int, y0: int, fade: float | None = None) -> None:
    """Removes one fading "show taps" dot by inverting its alpha blend,
    obs = under * (1 - fade*A) + fade*P, then filling the opaque ring from its
    neighbours. Without a given fade, the centre comes from the ring and the
    fade is the one that leaves the least circular structure."""
    h, w, _ = a.shape
    cx, cy = (x0, y0) if fade is not None else _find_centre(a, x0, y0)
    top, bottom = max(0, cy - R), min(h, cy + R + 1)  # clip at the screen edge
    left, right = max(0, cx - R), min(w, cx + R + 1)
    sprite = (slice(top - cy + R, bottom - cy + R), slice(left - cx + R, right - cx + R))
    region = (slice(top, bottom), slice(left, right))
    alpha, premultiplied, radius = SPRITE_A[sprite], SPRITE_P[sprite], _RADIUS[sprite]
    if fade is None:
        fade = min(np.arange(0.02, 1.0001, 0.01), key=lambda f: _leftover(*_unblend(a[region], alpha, premultiplied, f), radius))
    clean, opaque = _unblend(a[region], alpha, premultiplied, fade)
    if opaque.any():
        clean[opaque] = np.median(clean[~opaque], axis=0)
        for _ in range(80):
            smooth = (np.roll(clean, 1, 0) + np.roll(clean, -1, 0) + np.roll(clean, 1, 1) + np.roll(clean, -1, 1)) / 4
            clean[opaque] = smooth[opaque]
    a[region] = np.clip(clean, 0, 255)


# README stills (submission/README.md links these names).
README_STILLS = {
    '01-onboarding-purpose.png': '01a',
    '02-home-map.png': '05a',
    '03-field-question.png': '06a',
    '04-evidence-checks.png': '09a',
    '05-review.png': '11a',  # no review screenshot exists; the submitted screen is the closest
    '06-profile-impact.png': '13a',
}


def main() -> None:
    (SCREENS / 'new').mkdir(parents=True, exist_ok=True)
    for shot, name in SHOTS.items():
        pixels = np.asarray(Image.open(SOURCE / name).convert('RGB'), dtype=np.float64).copy()
        for dot in TAP_DOTS.get(shot, []):
            remove_tap_dot(pixels, *dot)
        image = Image.fromarray(np.rint(pixels).astype(np.uint8))
        draw = ImageDraw.Draw(image)
        for box in REDACTIONS.get(shot, []):
            draw.rounded_rectangle(box, radius=10, fill=(18, 48, 71))
        image.save(SCREENS / 'new' / f'{shot}.png', optimize=True)
        print(f'{shot}.png <- {name} {image.size}')
    for still, shot in README_STILLS.items():
        Image.open(SCREENS / 'new' / f'{shot}.png').save(SCREENS / still, optimize=True)
        print(f'{still} <- {shot}.png')


if __name__ == '__main__':
    main()
