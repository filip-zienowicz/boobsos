#!/usr/bin/env python3
"""
BoobsOS — generator tapet pulpitu.

Generuje dwa pliki PNG (3840x2160):
  - boobsos.png      — gradient marki (jasniejszy, do dziennego/domyślnego użycia)
  - boobsos-dark.png — ciemniejszy wariant (nocny motyw)

Gradient: diagonalny 135deg, #2090C0 → #2563EB → #402090 (z BRANDING.md)
Logo: branding/logo/boobsos-logo.png wkomponowane wyśrodkowane (~30% szerokości)
z delikatną aureolą (glow) w kolorze cyan.

Uruchom z głównego katalogu repo:
  python3 branding/make-wallpaper.py
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    print("Pillow nie jest zainstalowane. Uruchom: pip install Pillow", file=sys.stderr)
    sys.exit(1)

# --- Konfiguracja ---
W, H = 3840, 2160
LOGO_RATIO = 0.30          # logo zajmuje ~30% szerokości tapety
LOGO_ALPHA = 0.92          # lekkie stonowanie logo (0.0=niewidoczne, 1.0=pełne)
GLOW_RADIUS = 40           # promień rozmycia dla efektu blasku
GLOW_ALPHA = 100           # intensywność blasku (0-255)

# Kolory marki (RGB)
CYAN   = (0x20, 0x90, 0xC0)   # #2090C0
BLUE   = (0x25, 0x63, 0xEB)   # #2563EB
VIOLET = (0x40, 0x20, 0x90)   # #402090
DARK_BG = (0x08, 0x0F, 0x1A)  # ciemny granat (tło dark)

REPO_ROOT = Path(__file__).parent.parent
LOGO_PATH = REPO_ROOT / "branding" / "logo" / "boobsos-logo.png"
OUT_DIR   = REPO_ROOT / "files" / "usr" / "share" / "backgrounds" / "boobsos"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def lerp_color(a, b, t):
    """Interpolacja liniowa między kolorami a i b dla wartości t ∈ [0,1]."""
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_gradient(w, h, color_a, color_b, color_c, dark=False):
    """
    Gradient diagonalny (135 deg): A → B → C.
    Punkt przejścia A→B: 0..0.45, B→C: 0.45..1.0.
    dark=True: przyciemnia gradient mieszając z ciemnym tłem.
    """
    img = Image.new("RGB", (w, h))
    px = img.load()

    # Współczynnik ciemności (0=normalny, 1=czarny)
    dark_factor = 0.55 if dark else 0.0

    for y in range(h):
        for x in range(w):
            # t: 0 (lewy górny róg) → 1 (prawy dolny)
            t = (x / w + y / h) / 2.0
            if t < 0.45:
                base = lerp_color(color_a, color_b, t / 0.45)
            else:
                base = lerp_color(color_b, color_c, (t - 0.45) / 0.55)

            if dark:
                base = lerp_color(base, DARK_BG, dark_factor)
            px[x, y] = base

    return img


def add_logo(bg, logo_path, alpha_factor=LOGO_ALPHA, glow=True):
    """
    Wkleja logo wyśrodkowane na tle, z opcjonalnym blaskiem cyan.
    Zwraca nową kopię tła z logo.
    """
    logo_orig = Image.open(logo_path).convert("RGBA")
    logo_w = int(bg.width * LOGO_RATIO)
    logo_h = int(logo_w * logo_orig.height / logo_orig.width)
    logo = logo_orig.resize((logo_w, logo_h), Image.LANCZOS)

    # Stonowanie — zmniejsz alpha
    if alpha_factor < 1.0:
        r, g, b, a = logo.split()
        a = a.point(lambda v: int(v * alpha_factor))
        logo = Image.merge("RGBA", (r, g, b, a))

    # Blask (glow): rozmyta wersja logo w kolorze cyan
    result = bg.copy().convert("RGBA")
    cx = (bg.width  - logo_w) // 2
    cy = (bg.height - logo_h) // 2

    if glow:
        # Tworzymy warstwę glow — monochromatyczna (biała) wersja alpha logo
        glow_layer = Image.new("RGBA", (logo_w, logo_h), (0, 0, 0, 0))
        _, _, _, alpha = logo.split()
        # Kolorujemy glow kolorem cyan
        glow_color = Image.new("RGBA", (logo_w, logo_h), (*CYAN, GLOW_ALPHA))
        glow_colored = Image.composite(
            glow_color,
            Image.new("RGBA", (logo_w, logo_h), (0, 0, 0, 0)),
            alpha
        )
        # Powiększ i rozmyj glow
        pad = GLOW_RADIUS * 2
        glow_big = Image.new("RGBA", (logo_w + 2*pad, logo_h + 2*pad), (0, 0, 0, 0))
        glow_big.paste(glow_colored, (pad, pad))
        glow_blurred = glow_big.filter(ImageFilter.GaussianBlur(GLOW_RADIUS))
        result.paste(glow_blurred, (cx - pad, cy - pad), glow_blurred)

    result.paste(logo, (cx, cy), logo)
    return result.convert("RGB")


def main():
    if not LOGO_PATH.exists():
        print(f"BŁĄD: logo nie znalezione: {LOGO_PATH}", file=sys.stderr)
        sys.exit(1)

    print(f"Generowanie tapet {W}x{H} do {OUT_DIR} ...")

    # --- Tapeta normalna ---
    print("  [1/2] boobsos.png (jasny gradient marki)...")
    bg = make_gradient(W, H, CYAN, BLUE, VIOLET, dark=False)
    result = add_logo(bg, LOGO_PATH)
    out = OUT_DIR / "boobsos.png"
    result.save(str(out), "PNG", optimize=False)
    print(f"        Zapisano: {out}")

    # --- Tapeta ciemna ---
    print("  [2/2] boobsos-dark.png (ciemny wariant)...")
    bg_dark = make_gradient(W, H, CYAN, BLUE, VIOLET, dark=True)
    result_dark = add_logo(bg_dark, LOGO_PATH, alpha_factor=0.85)
    out_dark = OUT_DIR / "boobsos-dark.png"
    result_dark.save(str(out_dark), "PNG", optimize=False)
    print(f"        Zapisano: {out_dark}")

    # Weryfikacja
    for path in (out, out_dark):
        img = Image.open(path)
        print(f"  OK: {path.name}: {img.size[0]}x{img.size[1]} {img.mode}")

    print("Gotowe.")


if __name__ == "__main__":
    main()
