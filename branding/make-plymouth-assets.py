#!/usr/bin/env python3
"""
BoobsOS — generator assetów Plymouth.

Generuje:
  - watermark.png — logo BoobsOS (512x512 RGBA) dla motywu two-step
    (używane jako "watermark" — wyśrodkowane duże logo na ekranie startowym)

Uruchom z głównego katalogu repo:
  python3 branding/make-plymouth-assets.py
"""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow nie jest zainstalowane.", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = Path(__file__).parent.parent
LOGO_PATH = REPO_ROOT / "branding" / "logo" / "boobsos-logo.png"
PLYMOUTH_DIR = REPO_ROOT / "files" / "usr" / "share" / "plymouth" / "themes" / "boobsos"
PLYMOUTH_DIR.mkdir(parents=True, exist_ok=True)

def main():
    logo = Image.open(LOGO_PATH).convert("RGBA")

    # watermark.png — logo w oryginalnym rozmiarze (512x512)
    # two-step wyświetli go wyśrodkowany na ekranie bootowania
    watermark = logo.resize((256, 256), Image.LANCZOS)
    out = PLYMOUTH_DIR / "watermark.png"
    watermark.save(str(out), "PNG")
    print(f"Zapisano: {out} ({watermark.size})")

if __name__ == "__main__":
    main()
