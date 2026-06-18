#!/usr/bin/env bash
# rebuild-qcow2.sh — pełny cykl: obraz → warstwa demo → rejestr → storage → qcow2.
# Używane do iteracji podglądu VM. Wynik: bib-output/qcow2/disk.qcow2.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo ">>> [1/5] build obrazu boobsos:dev"
DOCKER_BUILDKIT=1 docker build -f Containerfile -t boobsos:dev .

echo ">>> [2/5] warstwa demo boobsos-vm:dev (user boobs + autologin)"
docker build -f Containerfile.vm -t boobsos-vm:dev .

echo ">>> [3/5] push do lokalnego rejestru"
docker start boobs-reg 2>/dev/null || docker run -d --name boobs-reg -p 5000:5000 registry:2
sleep 1
docker tag boobsos-vm:dev localhost:5000/boobsos-vm:dev
docker push localhost:5000/boobsos-vm:dev

echo ">>> [4/5] odśwież container-storage (podman z wnętrza obrazu)"
sudo rm -rf /var/lib/containers/storage
sudo mkdir -p /var/lib/containers/storage
sudo docker run --rm --privileged --network host --security-opt label=disable \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  --entrypoint /usr/bin/podman boobsos:dev \
  pull --tls-verify=false localhost:5000/boobsos-vm:dev

echo ">>> [5/5] bib → qcow2"
sudo rm -rf bib-output && mkdir -p bib-output
sudo docker run --rm --privileged --network host --security-opt label=disable \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$PWD/bib-output":/output \
  -v "$PWD/bib-config.toml":/config.toml:ro \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 --rootfs ext4 --config /config.toml --local \
  localhost:5000/boobsos-vm:dev

echo ">>> GOTOWE: bib-output/qcow2/disk.qcow2"
