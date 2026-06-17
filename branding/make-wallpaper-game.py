#!/usr/bin/env python3
"""
BoobsOS Game — generator tapet pulpitu (czerwony motyw).

Generuje dwa pliki PNG (3840x2160) do editions/game/files/:
  - boobsos.png      — gradient czerwony marki Game (jasny wariant)
  - boobsos-dark.png — ciemniejszy wariant (nocny motyw)

Gradient: diagonalny 135deg, #F87171 → #DC2626 → #7F1D1D (czerwona paleta Game)
Logo: branding/logo/boobsos-logo.png wkomponowane wyśrodkowane (~30% szerokości)
z delikatną aureolą (glow) w kolorze czerwonym.

Uruchom z głównego katalogu repo:
  python3 branding/make-wallpaper-game.py
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

# Kolory marki Game (RGB) — czerwona paleta
RED_LIGHT = (0xF8, 0x71, 0x71)   # #F87171 — jaśniejszy czerwony
RED       = (0xDC, 0x26, 0x26)   # #DC2626 — brand red (akcent)
RED_DARK  = (0x7F, 0x1D, 0x1D)   # #7F1D1D — ciemny czerwony
DARK_BG   = (0x1A, 0x05, 0x05)   # bardzo ciemny bordo (tło dark)

REPO_ROOT = Path(__file__).parent.parent
LOGO_PATH = REPO_ROOT / "branding" / "logo" / "boobsos-logo.png"
OUT_DIR   = REPO_ROOT / "editions" / "game" / "files" / "usr" / "share" / "backgrounds" / "boobsos"
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


def add_logo(bg, logo_path, alpha_factor=LOGO_ALPHA, glow=True, glow_color=RED):
    """
    Wkleja logo wyśrodkowane na tle, z opcjonalnym blaskiem w kolorze glow_color.
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

    # Blask (glow): rozmyta wersja logo w kolorze glow_color
    result = bg.copy().convert("RGBA")
    cx = (bg.width  - logo_w) // 2
    cy = (bg.height - logo_h) // 2

    if glow:
        _, _, _, alpha = logo.split()
        # Kolorujemy glow podanym kolorem
        glow_color_img = Image.new("RGBA", (logo_w, logo_h), (*glow_color, GLOW_ALPHA))
        glow_colored = Image.composite(
            glow_color_img,
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
        print(f"BLAD: logo nie znalezione: {LOGO_PATH}", file=sys.stderr)
        sys.exit(1)

    print(f"Generowanie tapet Game {W}x{H} do {OUT_DIR} ...")
    print(f"  Paleta: #F87171 -> #DC2626 -> #7F1D1D (czerwony motyw Game)")

    # --- Tapeta normalna (czerwona) ---
    print("  [1/2] boobsos.png (czerwony gradient marki Game)...")
    bg = make_gradient(W, H, RED_LIGHT, RED, RED_DARK, dark=False)
    result = add_logo(bg, LOGO_PATH, glow_color=RED_LIGHT)
    out = OUT_DIR / "boobsos.png"
    result.save(str(out), "PNG", optimize=False)
    print(f"        Zapisano: {out}")

    # --- Tapeta ciemna (ciemniejszy czerwony) ---
    print("  [2/2] boobsos-dark.png (ciemny wariant czerwony)...")
    bg_dark = make_gradient(W, H, RED_LIGHT, RED, RED_DARK, dark=True)
    result_dark = add_logo(bg_dark, LOGO_PATH, alpha_factor=0.85, glow_color=RED_LIGHT)
    out_dark = OUT_DIR / "boobsos-dark.png"
    result_dark.save(str(out_dark), "PNG", optimize=False)
    print(f"        Zapisano: {out_dark}")

    # Weryfikacja
    for path in (out, out_dark):
        img = Image.open(path)
        assert img.size == (W, H), f"Nieprawidlowy rozmiar: {img.size}"
        print(f"  OK: {path.name}: {img.size[0]}x{img.size[1]} {img.mode}")

    print("Gotowe.")


if __name__ == "__main__":
    main()
