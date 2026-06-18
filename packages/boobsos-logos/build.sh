#!/usr/bin/env bash
# build.sh — buduje boobsos-logos RPM (fork fedora-logos) w kontenerze Fedora 44
# Uruchomienie: bash packages/boobsos-logos/build.sh
# Wynik trafia do: packages/out/boobsos-logos-44.1-1.fc44.noarch.rpm
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/packages/out"
mkdir -p "${OUT_DIR}"

echo "==> Buduję boobsos-logos w kontenerze Fedora 44..."

# Użyj docker jeśli dostępny i działający, w przeciwnym razie podman
if docker info &>/dev/null 2>&1; then
    CONTAINER_RUNTIME="docker"
else
    CONTAINER_RUNTIME="podman"
fi
echo "    Używam: ${CONTAINER_RUNTIME}"

${CONTAINER_RUNTIME} run --rm \
    -v "${REPO_ROOT}:/src:ro" \
    -v "${OUT_DIR}:/out" \
    fedora:44 \
    bash -c '
set -euo pipefail

# -------------------------------------------------------------------------
# 1. Instalacja narzędzi
# -------------------------------------------------------------------------
echo "--- [1/6] Instaluję narzędzia..."
dnf -y install \
    rpm-build rpmdevtools \
    fedora-logos \
    2>&1 | tail -10

rpmdev-setuptree
TOPDIR=$(rpm --eval "%{_topdir}")
BUILDDIR="${TOPDIR}/BUILD"

# -------------------------------------------------------------------------
# 2. Zbuduj drzewo plików na bazie zainstalowanego fedora-logos
# -------------------------------------------------------------------------
echo "--- [2/6] Wyciągam drzewo plików z fedora-logos..."

TREEDIR="${BUILDDIR}/boobsos-logos-tree"
mkdir -p "${TREEDIR}"

# Pobierz listę plików z zainstalowanego pakietu i skopiuj je
rpm -ql fedora-logos | while IFS= read -r fpath; do
    if [[ -f "$fpath" ]]; then
        destdir="${TREEDIR}/$(dirname "$fpath")"
        mkdir -p "$destdir"
        cp -a "$fpath" "$destdir/"
    elif [[ -d "$fpath" ]]; then
        mkdir -p "${TREEDIR}/${fpath}"
    elif [[ -L "$fpath" ]]; then
        # Dowiązania symboliczne
        destdir="${TREEDIR}/$(dirname "$fpath")"
        mkdir -p "$destdir"
        cp -a "$fpath" "$destdir/"
    fi
done

echo "--- Liczba skopiowanych plików (bez katalogów):"
find "${TREEDIR}" -type f | wc -l

# -------------------------------------------------------------------------
# 3. Zastąp pixmapy Anacondy brandingiem BoobsOS
# -------------------------------------------------------------------------
echo "--- [3/6] Nadpisuję pixmapy Anacondy brandingiem BoobsOS..."

PXSRC="/src/packages/boobsos-anaconda-branding/pixmaps"

# Pixmapy, które zamieniamy:
#   sidebar-logo.png  — logo (150x150)
#   sidebar-bg.png    — tło paska bocznego (230x600)
#   topbar-bg.png     — tło paska górnego (1920x64)
#
# Wyszukujemy WSZYSTKIE wystąpienia tych nazw w drzewie Anacondy
# (top-level + subdirektoria atomic/cloud/server/silverblue/workstation).

ANACONDA_PX="${TREEDIR}/usr/share/anaconda/pixmaps"

replace_if_exists() {
    local src="$1"
    local dst="$2"
    if [[ -f "$dst" ]]; then
        echo "  Zastępuję: ${dst#${TREEDIR}}"
        install -m644 "$src" "$dst"
    else
        echo "  Pomijam (nie istnieje w oryginale): ${dst#${TREEDIR}}"
    fi
}

# Dla pewności: utwórz top-level, jeśli katalog istnieje lub fedora-logos go ma
if [[ -d "${ANACONDA_PX}" ]]; then
    replace_if_exists "${PXSRC}/sidebar-logo.png" "${ANACONDA_PX}/sidebar-logo.png"
    replace_if_exists "${PXSRC}/sidebar-bg.png"   "${ANACONDA_PX}/sidebar-bg.png"
    replace_if_exists "${PXSRC}/topbar-bg.png"    "${ANACONDA_PX}/topbar-bg.png"
    # anaconda_header.png — jeśli istnieje, zastępujemy topbar-bg (najbliższy odpowiednik)
    replace_if_exists "${PXSRC}/topbar-bg.png"    "${ANACONDA_PX}/anaconda_header.png"
else
    echo "  UWAGA: ${ANACONDA_PX} nie istnieje w fedora-logos — pomijam"
fi

# Warianty (atomic, cloud, server, silverblue, workstation)
for variant in atomic cloud server silverblue workstation; do
    VDIR="${ANACONDA_PX}/${variant}"
    if [[ -d "$VDIR" ]]; then
        replace_if_exists "${PXSRC}/sidebar-logo.png" "${VDIR}/sidebar-logo.png"
        replace_if_exists "${PXSRC}/sidebar-bg.png"   "${VDIR}/sidebar-bg.png"
        replace_if_exists "${PXSRC}/topbar-bg.png"    "${VDIR}/topbar-bg.png"
        replace_if_exists "${PXSRC}/topbar-bg.png"    "${VDIR}/anaconda_header.png"
    fi
done

echo "--- Po zamianie, liczba plików w drzewie:"
find "${TREEDIR}" -type f | wc -l

# -------------------------------------------------------------------------
# 4. Wygeneruj listę %files do specfile
# -------------------------------------------------------------------------
echo "--- [4/6] Generuję listę plików dla rpmbuild..."

FILELIST="${BUILDDIR}/boobsos-logos.filelist"
> "${FILELIST}"

# Przejdź przez wszystkie pliki i linki w drzewie
find "${TREEDIR}" \( -type f -o -type l \) | sort | while IFS= read -r fpath; do
    # Ścieżka względem drzewa (= ścieżka w systemie)
    relpath="${fpath#${TREEDIR}}"
    echo "${relpath}" >> "${FILELIST}"
done

# Katalogi — dodaj tylko te, które RPM musi zarządzać
# (pomijamy /usr, /usr/share itp. — standardowe, nie zarządzane przez RPM)
# Wystarczy lista plików; katalogi są tworzone automatycznie przez rpmbuild.

echo "--- Liczba wpisów w filelist: $(wc -l < ${FILELIST})"
echo "--- Pierwsze 10 wpisów:"
head -10 "${FILELIST}"

# -------------------------------------------------------------------------
# 5. Skopiuj spec do BUILD i zbuduj RPM
# -------------------------------------------------------------------------
echo "--- [5/6] Buduję RPM..."

install -Dm644 /src/packages/boobsos-logos/boobsos-logos.spec \
    "${TOPDIR}/SPECS/boobsos-logos.spec"

rpmbuild -bb \
    --define "_topdir ${TOPDIR}" \
    --define "_builddir ${BUILDDIR}" \
    "${TOPDIR}/SPECS/boobsos-logos.spec"

# -------------------------------------------------------------------------
# 6. Kopiuj wynik
# -------------------------------------------------------------------------
echo "--- [6/6] Kopiuję RPM do /out/..."
find "${TOPDIR}/RPMS" -name "boobsos-logos-*.rpm" -exec cp -v {} /out/ \;

echo ""
echo "==> Build zakończony. Pliki:"
find /out -name "boobsos-logos-*.rpm" | sort
'

echo ""
echo "==> Build zakończony. Pliki RPM w ${OUT_DIR}:"
find "${OUT_DIR}" -name "boobsos-logos-*.rpm" | sort

# -------------------------------------------------------------------------
# WERYFIKACJA — uruchamiamy w kontenerze (rpm nie jest dostepne na hoście)
# -------------------------------------------------------------------------
RPM_FILE=$(find "${OUT_DIR}" -name "boobsos-logos-*.rpm" | head -1)
if [[ -z "$RPM_FILE" ]]; then
    echo "BLAD: Nie znaleziono zbudowanego RPM!" >&2
    exit 1
fi

echo ""
echo "==> WERYFIKACJA: ${RPM_FILE}"

OUR_PNG="${REPO_ROOT}/packages/boobsos-anaconda-branding/pixmaps/sidebar-logo.png"

${CONTAINER_RUNTIME} run --rm \
    -v "${RPM_FILE}:/pkg.rpm:ro" \
    -v "${OUR_PNG}:/our-sidebar-logo.png:ro" \
    fedora:44 bash -c '
set -euo pipefail
dnf -y install cpio 2>&1 | tail -2

echo ""
echo "--- Provides:"
rpm -qp --provides /pkg.rpm | sort

echo ""
echo "--- Obsoletes:"
rpm -qp --obsoletes /pkg.rpm

echo ""
echo "--- Conflicts:"
rpm -qp --conflicts /pkg.rpm

echo ""
echo "--- Liczba plikow w RPM:"
rpm -qpl /pkg.rpm | wc -l

echo ""
echo "--- Pliki sidebar-logo.png w RPM:"
rpm -qpl /pkg.rpm | grep sidebar-logo

echo ""
echo "--- Weryfikacja MD5 sidebar-logo.png (musi pasowac do BoobsOS):"
TMPDIR=$(mktemp -d)
cd "${TMPDIR}"
rpm2cpio /pkg.rpm | cpio -id --quiet "./usr/share/anaconda/pixmaps/sidebar-logo.png" 2>/dev/null
MD5_OURS=$(md5sum /our-sidebar-logo.png | cut -d" " -f1)
MD5_RPM=$(md5sum "${TMPDIR}/usr/share/anaconda/pixmaps/sidebar-logo.png" | cut -d" " -f1)
echo "  MD5 (nasz oryginal): ${MD5_OURS}"
echo "  MD5 (z RPM):         ${MD5_RPM}"
if [[ "${MD5_OURS}" == "${MD5_RPM}" ]]; then
    echo "  WYNIK: OK - sidebar-logo.png w RPM to labedz BoobsOS"
else
    echo "  WYNIK: BLAD - MD5 sie roznia!"
    exit 1
fi
'

echo ""
echo "==> Weryfikacja zakonczona."
