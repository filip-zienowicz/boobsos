#!/usr/bin/env bash
# build-iso.sh — buduje instalacyjne ISO BoobsOS przy użyciu bootc-image-builder
#
# Użycie:
#   bash iso/build-iso.sh [IMAGE_REF]
#
# IMAGE_REF — referencja do obrazu OCI BoobsOS, np.:
#   registry.gitlab.cycr.us/fzienowicz/boobsos:latest
#   localhost/boobsos:dev   (domyślne — lokalny obraz w podman storage)
#
# Wynik: iso-output/bootiso/install.iso
# UWAGA: dodaj iso-output/ do .gitignore (bib generuje tam spore pliki)
#
# Wymagania:
#   - podman (Fedora 44)
#   - sudo / uprawnienia do --privileged
#   - obraz OCI BoobsOS dostępny lokalnie lub w rejestrze
#
# Branding: nazwa produktu z os-release (PRETTY_NAME="BoobsOS"),
# logo/grafiki z paczki boobsos-anaconda-branding (zainstalowanej w obrazie OCI).
set -euo pipefail

# Domyślna referencja: lokalny obraz
IMAGE_REF="${1:-localhost/boobsos:dev}"

# Katalog wyjściowy (względny do katalogu z którego uruchamiamy)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/iso-output"
CONFIG_FILE="${SCRIPT_DIR}/config.toml"

# Definicja dystrybucji dla bib. Obraz ma os-release ID=boobsos VERSION_ID=44,
# więc bib szuka defs/boobsos-44.yaml (którego nie ma wbudowanego → montujemy nasz).
# Treść == fedora-40.yaml z bib (lista pakietów instalatora anaconda-iso).
DEFS_FILE="${SCRIPT_DIR}/defs/boobsos-44.yaml"

BIB_IMAGE="quay.io/centos-bootc/bootc-image-builder:latest"

echo "==> BoobsOS ISO Builder"
echo "    IMAGE_REF  : ${IMAGE_REF}"
echo "    CONFIG     : ${CONFIG_FILE}"
echo "    OUTPUT_DIR : ${OUTPUT_DIR}"
echo "    BIB_IMAGE  : ${BIB_IMAGE}"
echo ""

mkdir -p "${OUTPUT_DIR}"

# Wykryj czy obraz jest lokalny (localhost/ lub bez rejestru)
LOCAL_FLAG=""
if [[ "${IMAGE_REF}" == localhost/* ]] || [[ "${IMAGE_REF}" != *"."* ]]; then
    LOCAL_FLAG="--local"
    echo "    Tryb: lokalny obraz (${LOCAL_FLAG})"
else
    echo "    Tryb: obraz z rejestru"
fi

echo "==> Uruchamiam bootc-image-builder..."
sudo podman run \
    --rm \
    --privileged \
    --security-opt label=type:unconfined_t \
    -v "${CONFIG_FILE}:/config.toml:ro" \
    -v "${DEFS_FILE}:/usr/share/bootc-image-builder/defs/boobsos-44.yaml:ro" \
    -v "${OUTPUT_DIR}:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    "${BIB_IMAGE}" \
    --type anaconda-iso \
    --rootfs ext4 \
    --config /config.toml \
    ${LOCAL_FLAG} \
    "${IMAGE_REF}"

echo ""
echo "==> Gotowe! Plik ISO:"
find "${OUTPUT_DIR}/bootiso" -name "*.iso" 2>/dev/null | sort || \
    find "${OUTPUT_DIR}" -name "*.iso" 2>/dev/null | sort || \
    echo "    Nie znaleziono pliku .iso w ${OUTPUT_DIR}"
