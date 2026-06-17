#!/usr/bin/env bash
# tests/test-image.sh <image-ref>
#
# Szybka (kontenerowa, bez bootowania) walidacja zbudowanego obrazu BoobsOS.
# Wykrywa edycję z VARIANT_ID w os-release: desktop → dev, game → game.
#
# Użycie:
#   ./tests/test-image.sh localhost/boobsos:dev
#   ./tests/test-image.sh ghcr.io/filip-zienowicz/boobsos:abc1234

set -uo pipefail

IMAGE="${1:-}"
if [[ -z "$IMAGE" ]]; then
  echo "Użycie: $0 <image-ref>" >&2
  exit 1
fi

PASS=0
FAIL=0

# ── helpers ──────────────────────────────────────────────────────────────────

# Uruchamia jednorazowy kontener z podanym poleceniem bash.
# Zwraca kod wyjścia kontenera.
run_in_container() {
  podman run --rm --pull=never "$IMAGE" bash -c "$1" 2>/dev/null
}

check() {
  local label="$1"
  local cmd="$2"
  if run_in_container "$cmd"; then
    echo "PASS: $label"
    (( PASS++ ))
  else
    echo "FAIL: $label"
    (( FAIL++ ))
  fi
}

check_negative() {
  local label="$1"
  local cmd="$2"
  if ! run_in_container "$cmd"; then
    echo "PASS: $label"
    (( PASS++ ))
  else
    echo "FAIL: $label (obecny, a nie powinien być)"
    (( FAIL++ ))
  fi
}

# ── wykryj edycję ─────────────────────────────────────────────────────────────

echo "==> Wykrywam edycję obrazu: $IMAGE"
VARIANT_ID=$(run_in_container "grep '^VARIANT_ID=' /usr/lib/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"'" || true)
echo "    VARIANT_ID=${VARIANT_ID:-<brak>}"
echo ""

# ── wspólne testy (dev i game) ────────────────────────────────────────────────

echo "--- Wspólne ---"

# os-release
check "os-release: NAME=\"BoobsOS\"" \
  "grep -qxF 'NAME=\"BoobsOS\"' /usr/lib/os-release"

check "os-release: ID=boobsos" \
  "grep -qxF 'ID=boobsos' /usr/lib/os-release"

check "os-release: PRETTY_NAME zawiera BoobsOS" \
  "grep -q 'BoobsOS' /usr/lib/os-release && grep -q '^PRETTY_NAME=' /usr/lib/os-release"

# boobsos-edition
check "command: boobsos-edition istnieje i jest wykonywalny" \
  "command -v boobsos-edition && test -x \"\$(command -v boobsos-edition)\""

# repozytorium Cycrus
check "plik: /etc/yum.repos.d/cycrus.repo istnieje" \
  "test -f /etc/yum.repos.d/cycrus.repo"

# branding
check "branding: /usr/share/icons/hicolor/256x256/apps/boobsos.png" \
  "test -f /usr/share/icons/hicolor/256x256/apps/boobsos.png"

check "branding: /usr/share/backgrounds/boobsos/boobsos.png" \
  "test -f /usr/share/backgrounds/boobsos/boobsos.png"

check "branding: katalog /usr/share/plymouth/themes/boobsos" \
  "test -d /usr/share/plymouth/themes/boobsos"

# dconf
check "dconf: welcome-dialog-last-shown-version w 00-boobsos" \
  "grep -q 'welcome-dialog-last-shown-version' /etc/dconf/db/local.d/00-boobsos"

check "dconf: dash-to-panel@jderose9.github.com w 00-boobsos" \
  "grep -q 'dash-to-panel@jderose9.github.com' /etc/dconf/db/local.d/00-boobsos"

# usługi — systemctl is-enabled działa offline (sprawdza symlinki/presety)
check "service: firewalld.service enabled" \
  "systemctl is-enabled firewalld.service 2>/dev/null | grep -qE '^(enabled|enabled-runtime)$'"

check "service: bootc-fetch-apply-updates.timer enabled" \
  "systemctl is-enabled bootc-fetch-apply-updates.timer 2>/dev/null | grep -qE '^(enabled|enabled-runtime)$'"

# bootc
check "command: bootc dostępny" \
  "command -v bootc"

echo ""

# ── testy specyficzne dla edycji ──────────────────────────────────────────────

case "${VARIANT_ID}" in

  desktop)
    echo "--- Dev (VARIANT_ID=desktop) ---"

    check "dev: command -v kubectl" "command -v kubectl"
    check "dev: command -v terraform" "command -v terraform"
    check "dev: command -v docker" "command -v docker"
    check "dev: command -v code" "command -v code"
    check "dev: command -v helm" "command -v helm"
    check "dev: command -v ansible" "command -v ansible"

    check "dconf: accent-color='blue'" \
      "grep -qF \"accent-color='blue'\" /etc/dconf/db/local.d/00-boobsos"
    ;;

  game)
    echo "--- Game (VARIANT_ID=game) ---"

    # Obecne pakiety / binarki
    check "game: rpm -q gamemode" "rpm -q gamemode"
    check "game: rpm -q mangohud" "rpm -q mangohud"
    check "game: rpm -q steam-devices" "rpm -q steam-devices"
    check "game: command -v vulkaninfo" "command -v vulkaninfo"

    # Usługa GPU autorebase
    check "game: boobsos-gpu-autorebase.service enabled" \
      "systemctl is-enabled boobsos-gpu-autorebase.service 2>/dev/null | grep -qE '^(enabled|enabled-runtime)$'"

    # Dconf — czerwony akcent
    check "dconf: accent-color='red'" \
      "grep -qF \"accent-color='red'\" /etc/dconf/db/local.d/00-boobsos"

    # NEGATYWNE — narzędzia DevOps nie powinny być w edycji gamingowej
    check_negative "game: BRAK kubectl" "command -v kubectl"
    check_negative "game: BRAK terraform" "command -v terraform"
    check_negative "game: BRAK code (VS Code)" "command -v code"
    ;;

  *)
    echo "WARN: Nieznany VARIANT_ID='${VARIANT_ID}' — pomijam testy edycji."
    ;;
esac

# ── podsumowanie ──────────────────────────────────────────────────────────────

echo ""
echo "=============================="
echo "Wyniki: PASS=$PASS  FAIL=$FAIL"
echo "=============================="

if (( FAIL > 0 )); then
  echo "RESULT: FAIL — obraz nie przeszedł testów."
  exit 1
fi

echo "RESULT: OK — wszystkie testy przeszły."
exit 0
