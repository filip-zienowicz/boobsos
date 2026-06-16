#!/usr/bin/env bash
# run-vm.sh — uruchamia BoobsOS (obraz qcow2 z bootc-image-builder) w QEMU/KVM.
#
# WAŻNE: uruchom to BEZPOŚREDNIO na hoście (fz-vm), w swoim terminalu —
# NIE przez sandbox agenta (tam qemu jest blokowany).
#
# Dostęp (oba nasłuchują WYŁĄCZNIE na adresie Tailscale):
#   • VNC: <TS_IP>:5900   (klient VNC, hasło poniżej)
#   • SSH: ssh boobs@<TS_IP> -p 2222   (hasło: boobs)
set -euo pipefail

DISK="${DISK:-/home/fzienowicz/boobsos/bib-output/qcow2/disk.qcow2}"
TS_IP="${TS_IP:-100.102.29.104}"
VNC_PASS="${VNC_PASS:-BoobsVNC2026}"
VARS="/home/fzienowicz/boobsos/OVMF_VARS_boobs.fd"
SERIAL="/home/fzienowicz/boobsos/vm-serial.log"

# świeża kopia zmiennych UEFI przy każdym starcie
cp /usr/share/OVMF/OVMF_VARS_4M.fd "$VARS"

echo ">>> Start BoobsOS VM..."
echo "    VNC: ${TS_IP}:5900  (hasło: ${VNC_PASS})"
echo "    SSH: ssh boobs@${TS_IP} -p 2222  (hasło: boobs)"
echo "    Serial log: ${SERIAL}"

sudo qemu-system-x86_64 \
  -name BoobsOS \
  -machine q35,accel=kvm \
  -cpu host -smp 4 -m 4096 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file="$VARS" \
  -drive file="$DISK",if=virtio,format=qcow2,cache=writeback \
  -device virtio-vga \
  -object secret,id=vncpw,data="$VNC_PASS" \
  -vnc "${TS_IP}:0,password-secret=vncpw" \
  -netdev user,id=net0,hostfwd=tcp:${TS_IP}:2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -serial file:"$SERIAL" \
  -daemonize

echo ">>> VM wystartowała (daemonized). Połącz się klientem VNC: ${TS_IP}:5900"
