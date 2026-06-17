Name:           boobsos-anaconda-branding
Version:        1.0.0
Release:        1%{?dist}
Summary:        Grafiki brandingowe BoobsOS dla instalatora Anaconda
License:        MIT
BuildArch:      noarch

%description
Paczka dostarcza zasoby graficzne BoobsOS dla instalatora Anaconda:
- sidebar-logo.png — logo (150x150 RGBA) na pasku bocznym instalatora
- boobsos-logo.png — pelne logo BoobsOS (200x200 RGBA)
- sidebar-bg.png   — tlo paska bocznego (230x600 RGB, gradient marki)
- topbar-bg.png    — tlo gornego paska (1920x64 RGB, gradient marki)

Pixmapy generowane sa z branding/logo/boobsos-logo.png przy pomocy
make-anaconda-art.py (Pillow). Kolory marki: #2090C0 -> #2563EB -> #402090.
Odtworz: python3 packages/boobsos-anaconda-branding/make-anaconda-art.py

%install
# Pixmapy sa wstepnie wygenerowane i przechowywane w repo
# pod packages/boobsos-anaconda-branding/pixmaps/
# W kontenerze build-rpm.sh repo jest podmontowane pod /src (ro).
PXDIR="/src/packages/boobsos-anaconda-branding/pixmaps"

install -Dm644 "${PXDIR}/sidebar-logo.png" \
    %{buildroot}%{_datadir}/anaconda/pixmaps/sidebar-logo.png
install -Dm644 "${PXDIR}/boobsos-logo.png" \
    %{buildroot}%{_datadir}/anaconda/pixmaps/boobsos-logo.png
install -Dm644 "${PXDIR}/sidebar-bg.png" \
    %{buildroot}%{_datadir}/anaconda/pixmaps/sidebar-bg.png
install -Dm644 "${PXDIR}/topbar-bg.png" \
    %{buildroot}%{_datadir}/anaconda/pixmaps/topbar-bg.png

%files
%{_datadir}/anaconda/pixmaps/sidebar-logo.png
%{_datadir}/anaconda/pixmaps/boobsos-logo.png
%{_datadir}/anaconda/pixmaps/sidebar-bg.png
%{_datadir}/anaconda/pixmaps/topbar-bg.png

%changelog
* Tue Jun 17 2026 BoobsOS <repo@cycx.io> - 1.0.0-1
- Pierwsza paczka brandingu Anaconda dla BoobsOS
