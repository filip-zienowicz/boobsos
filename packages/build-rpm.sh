#!/usr/bin/env bash
# build-rpm.sh — buduje paczkę RPM w kontenerze Fedora 44
# Użycie: bash packages/build-rpm.sh <package-name>
# Przykład: bash packages/build-rpm.sh boobsos-branding
set -euo pipefail

PACKAGE="${1:-}"
if [[ -z "$PACKAGE" ]]; then
    echo "Błąd: podaj nazwę paczki jako argument (np. boobsos-branding)" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPEC_FILE="packages/${PACKAGE}/${PACKAGE}.spec"
OUT_DIR="${REPO_ROOT}/packages/out"

if [[ ! -f "${REPO_ROOT}/${SPEC_FILE}" ]]; then
    echo "Błąd: nie znaleziono spec: ${REPO_ROOT}/${SPEC_FILE}" >&2
    exit 1
fi

mkdir -p "${OUT_DIR}"

echo "==> Buduję ${PACKAGE} w kontenerze Fedora 44..."

docker run --rm \
    -v "${REPO_ROOT}:/src:ro" \
    -v "${OUT_DIR}:/out" \
    -w /src \
    fedora:44 \
    bash -c '
set -euo pipefail
PACKAGE="'"${PACKAGE}"'"

echo "--- Instaluję narzędzia budowania..."
dnf -y install rpm-build rpmdevtools 2>&1 | tail -5

echo "--- Przygotowuję środowisko rpmbuild..."
rpmdev-setuptree
TOPDIR=$(rpm --eval "%{_topdir}")
SOURCEDIR=$(rpm --eval "%{_sourcedir}")

echo "--- Kopiuję pliki źródłowe z files/..."

# Ikony hicolor
for SIZE in 64x64 128x128 256x256 512x512; do
    install -Dm644 \
        "/src/files/usr/share/icons/hicolor/${SIZE}/apps/boobsos.png" \
        "${SOURCEDIR}/icons/${SIZE}/boobsos.png"
done

# Tapety
install -Dm644 \
    "/src/files/usr/share/backgrounds/boobsos/boobsos.png" \
    "${SOURCEDIR}/backgrounds/boobsos.png"
install -Dm644 \
    "/src/files/usr/share/backgrounds/boobsos/boobsos-dark.png" \
    "${SOURCEDIR}/backgrounds/boobsos-dark.png"

# Motyw Plymouth
install -Dm644 \
    "/src/files/usr/share/plymouth/themes/boobsos/boobsos.plymouth" \
    "${SOURCEDIR}/plymouth/boobsos.plymouth"
install -Dm644 \
    "/src/files/usr/share/plymouth/themes/boobsos/watermark.png" \
    "${SOURCEDIR}/plymouth/watermark.png"
install -Dm644 \
    "/src/files/usr/share/plymouth/themes/boobsos/boobsos-logo.png" \
    "${SOURCEDIR}/plymouth/boobsos-logo.png"

# Logo GDM
install -Dm644 \
    "/src/files/usr/share/pixmaps/boobsos-gdm-logo.png" \
    "${SOURCEDIR}/pixmaps/boobsos-gdm-logo.png"

echo "--- Pliki źródłowe gotowe:"
find "${SOURCEDIR}" -type f | sort

echo "--- Buduję RPM..."
rpmbuild -bb \
    --define "_topdir ${TOPDIR}" \
    "/src/packages/${PACKAGE}/${PACKAGE}.spec"

echo "--- Kopiuję wynik do /out/..."
find "${TOPDIR}/RPMS" -name "*.rpm" -exec cp -v {} /out/ \;

echo "--- Gotowe!"
find /out -name "*.rpm" | sort
'

echo ""
echo "==> Build zakończony. Pliki RPM:"
find "${OUT_DIR}" -name "*.rpm" | sort
