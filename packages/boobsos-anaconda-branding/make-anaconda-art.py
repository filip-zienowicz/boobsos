#!/usr/bin/env python3
"""
BoobsOS — generator pixmap dla instalatora Anaconda.

Generuje pliki PNG instalowane do /usr/share/anaconda/pixmaps/:
  - sidebar-logo.png  — logo na pasku bocznym (150x150 RGBA)
  - boobsos-logo.png  — pełne logo BoobsOS (200x200 RGBA)
  - sidebar-bg.png    — tło paska bocznego (230x600 RGB, gradient marki)
  - topbar-bg.png     — tło górnego paska (1920x64 RGB, gradient marki)

Uruchom z głównego katalogu repo:
  python3 packages/boobsos-anaconda-branding/make-anaconda-art.py

Pillow jest wymagane: pip install Pillow
"""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageFilter
except ImportError:
    print("Pillow nie jest zainstalowane. Uruchom: pip install Pillow", file=sys.stderr)
    sys.exit(1)

# Kolory marki (RGB)
CYAN   = (0x20, 0x90, 0xC0)   # #2090C0
BLUE   = (0x25, 0x63, 0xEB)   # #2563EB
VIOLET = (0x40, 0x20, 0x90)   # #402090

REPO_ROOT = Path(__file__).parent.parent.parent
LOGO_PATH = REPO_ROOT / "branding" / "logo" / "boobsos-logo.png"
OUT_DIR   = Path(__file__).parent / "pixmaps"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def lerp_color(a, b, t):
    """Interpolacja liniowa między kolorami a i b dla t ∈ [0,1]."""
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_gradient_h(w, h, color_a, color_b, color_c):
    """Gradient poziomy (A→B→C) w rozmiarze w×h, mode RGB."""
    img = Image.new("RGB", (w, h))
    px = img.load()
    for x in range(w):
        t = x / max(w - 1, 1)
        if t < 0.5:
            c = lerp_color(color_a, color_b, t / 0.5)
        else:
            c = lerp_color(color_b, color_c, (t - 0.5) / 0.5)
        for y in range(h):
            px[x, y] = c
    return img


def make_gradient_v(w, h, color_a, color_b, color_c):
    """Gradient pionowy (A→B→C) w rozmiarze w×h, mode RGB."""
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        if t < 0.5:
            c = lerp_color(color_a, color_b, t / 0.5)
        else:
            c = lerp_color(color_b, color_c, (t - 0.5) / 0.5)
        for x in range(w):
            px[x, y] = c
    return img


def place_logo_centered(bg, logo_path, logo_size, alpha=0.92, glow=True, glow_r=20, glow_a=90):
    """
    Wkleja logo na środku tła bg.
    logo_size: (w, h) docelowy rozmiar logo.
    Zwraca nową kopię (RGB).
    """
    logo_orig = Image.open(logo_path).convert("RGBA")
    logo = logo_orig.resize(logo_size, Image.LANCZOS)

    # Stonowanie alpha
    if alpha < 1.0:
        r, g, b, a = logo.split()
        a = a.point(lambda v: int(v * alpha))
        logo = Image.merge("RGBA", (r, g, b, a))

    result = bg.copy().convert("RGBA")
    cx = (bg.width  - logo_size[0]) // 2
    cy = (bg.height - logo_size[1]) // 2

    if glow:
        _, _, _, alpha_ch = logo.split()
        glow_color = Image.new("RGBA", logo_size, (*CYAN, glow_a))
        glow_img = Image.composite(
            glow_color,
            Image.new("RGBA", logo_size, (0, 0, 0, 0)),
            alpha_ch
        )
        pad = glow_r * 2
        glow_big = Image.new("RGBA", (logo_size[0] + 2*pad, logo_size[1] + 2*pad), (0, 0, 0, 0))
        glow_big.paste(glow_img, (pad, pad))
        glow_blurred = glow_big.filter(ImageFilter.GaussianBlur(glow_r))
        result.paste(glow_blurred, (cx - pad, cy - pad), glow_blurred)

    result.paste(logo, (cx, cy), logo)
    return result.convert("RGB")


def main():
    if not LOGO_PATH.exists():
        print(f"BŁĄD: logo nie znalezione: {LOGO_PATH}", file=sys.stderr)
        sys.exit(1)

    print(f"Generowanie pixmap Anaconda do: {OUT_DIR}")

    # --- sidebar-logo.png (150x150) ---
    # Pasek boczny Anacondy: mały kwadrat z logo (klasyczny sidebar-logo)
    print("  [1/4] sidebar-logo.png (150x150, RGBA, przezroczyste tło)...")
    logo_orig = Image.open(LOGO_PATH).convert("RGBA")
    sidebar_logo = logo_orig.resize((150, 150), Image.LANCZOS)
    out = OUT_DIR / "sidebar-logo.png"
    sidebar_logo.save(str(out), "PNG")
    print(f"        Zapisano: {out} {sidebar_logo.size} {sidebar_logo.mode}")

    # --- boobsos-logo.png (200x200) ---
    print("  [2/4] boobsos-logo.png (200x200, RGBA)...")
    boobsos_logo = logo_orig.resize((200, 200), Image.LANCZOS)
    out2 = OUT_DIR / "boobsos-logo.png"
    boobsos_logo.save(str(out2), "PNG")
    print(f"        Zapisano: {out2} {boobsos_logo.size} {boobsos_logo.mode}")

    # --- sidebar-bg.png (230x600) ---
    # Tło lewego paska bocznego Anacondy — gradient pionowy marki
    print("  [3/4] sidebar-bg.png (230x600, RGB)...")
    sidebar_bg = make_gradient_v(230, 600, CYAN, BLUE, VIOLET)
    sidebar_bg_with_logo = place_logo_centered(
        sidebar_bg, LOGO_PATH, (120, 120), alpha=0.90, glow=True, glow_r=15, glow_a=80
    )
    out3 = OUT_DIR / "sidebar-bg.png"
    # Zapisujemy bez logo na tle — Anaconda wyświetla sidebar-logo oddzielnie
    # Samo tło gradientu (bez logo) jest bezpieczniejsze dla layoutu instalatora
    sidebar_bg.save(str(out3), "PNG")
    print(f"        Zapisano: {out3} {sidebar_bg.size} {sidebar_bg.mode}")

    # --- topbar-bg.png (1920x64) ---
    # Tło górnego paska Anacondy — gradient poziomy marki
    print("  [4/4] topbar-bg.png (1920x64, RGB)...")
    topbar_bg = make_gradient_h(1920, 64, CYAN, BLUE, VIOLET)
    out4 = OUT_DIR / "topbar-bg.png"
    topbar_bg.save(str(out4), "PNG")
    print(f"        Zapisano: {out4} {topbar_bg.size} {topbar_bg.mode}")

    # Weryfikacja
    print("\nWeryfikacja:")
    for p in (out, out2, out3, out4):
        img = Image.open(p)
        print(f"  OK: {p.name}: {img.size[0]}x{img.size[1]} {img.mode}")

    print("\nGotowe.")


if __name__ == "__main__":
    main()
