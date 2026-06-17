#!/usr/bin/env python3
"""
BoobsOS Game — generator assetow Plymouth (czerwony motyw).

Generuje:
  - watermark.png   — logo BoobsOS (256x256 RGBA) dla motywu two-step
  - boobsos.plymouth — konfiguracja motywu z czerwonymi kolorami

Uruchom z glownego katalogu repo:
  python3 branding/make-plymouth-assets-game.py
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
PLYMOUTH_DIR = REPO_ROOT / "editions" / "game" / "files" / "usr" / "share" / "plymouth" / "themes" / "boobsos"
PLYMOUTH_DIR.mkdir(parents=True, exist_ok=True)


PLYMOUTH_CONF = """\
[Plymouth Theme]
Name=BoobsOS
Description=BoobsOS Game boot splash — czerwony gradient marki z logo i paskiem postępu
ModuleName=two-step

[two-step]
Font=Cantarell 12
TitleFont=Cantarell Light 30
# Katalog z animacja — korzystamy z animacji z motywu spinner
ImageDir=/usr/share/plymouth/themes/spinner
HorizontalAlignment=.5
VerticalAlignment=.5
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.5
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.7
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.65
Transition=none
TransitionDuration=0.0
# Tlo — ciemny bordo/czern (marka BoobsOS Game)
BackgroundStartColor=0x1A0505
BackgroundEndColor=0x2D0808
# Pasek postepu — czerwony akcent Game: #DC2626, tlo ciemne
ProgressBarBackgroundColor=0x3D0A0A
ProgressBarForegroundColor=0xDC2626
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false

[shutdown]
UseEndAnimation=false

[reboot]
UseEndAnimation=false

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Aktualizowanie systemu...
SubTitle=Nie wylaczaj komputera

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Aktualizacja BoobsOS...
SubTitle=Nie wylaczaj komputera

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Aktualizacja firmware...
SubTitle=Nie wylaczaj komputera

[system-reset]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Reset systemu...
SubTitle=Nie wylaczaj komputera
"""


def main():
    if not LOGO_PATH.exists():
        print(f"BLAD: logo nie znalezione: {LOGO_PATH}", file=sys.stderr)
        sys.exit(1)

    logo = Image.open(LOGO_PATH).convert("RGBA")

    # watermark.png — logo w rozmiarze 256x256
    watermark = logo.resize((256, 256), Image.LANCZOS)
    out = PLYMOUTH_DIR / "watermark.png"
    watermark.save(str(out), "PNG")
    print(f"Zapisano: {out} ({watermark.size})")

    # boobsos.plymouth — konfiguracja z czerwonymi kolorami
    conf_out = PLYMOUTH_DIR / "boobsos.plymouth"
    conf_out.write_text(PLYMOUTH_CONF, encoding="utf-8")
    print(f"Zapisano: {conf_out}")


if __name__ == "__main__":
    main()
