#!/usr/bin/env bash
# build.sh — pomocnik do lokalnego buildu obrazu BoobsOS
# Wymaga: podman, dostęp do ghcr.io (publiczny obraz bazy)
set -euo pipefail

IMAGE_NAME="boobsos"
IMAGE_TAG="dev"

echo "==> Budowanie obrazu ${IMAGE_NAME}:${IMAGE_TAG} ..."
podman build \
    --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
    --file Containerfile \
    .

echo ""
echo "==> Obraz zbudowany: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Możesz go przetestować w kontenerze (nie bootuje systemu, ale sprawdza warstwy):"
echo "  podman run --rm -it ${IMAGE_NAME}:${IMAGE_TAG} bash"
echo ""

# ---------------------------------------------------------------------------
# Generowanie ISO przez bootc-image-builder (odkomentuj i dostosuj):
#
# Wymaga: podman, uprawnienia root lub podman z --privileged,
#         obraz wypchnięty do rejestru (lub użyj lokalnego tagu przez --local).
#
# sudo podman run \
#     --rm \
#     --privileged \
#     --pull=newer \
#     --security-opt label=type:unconfined_t \
#     -v $(pwd)/output:/output \
#     -v /var/lib/containers/storage:/var/lib/containers/storage \
#     ghcr.io/osbuild/bootc-image-builder:latest \
#     --type iso \
#     --local \
#     localhost/${IMAGE_NAME}:${IMAGE_TAG}
#
# Wynik: output/bootiso/install.iso
#
# Alternatywnie po wypchnięciu do rejestru:
# sudo podman run ... ghcr.io/osbuild/bootc-image-builder:latest \
#     --type iso \
#     ghcr.io/<org>/boobsos:latest
# ---------------------------------------------------------------------------
