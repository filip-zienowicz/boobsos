# BoobsOS — Containerfile (Faza F1: minimalny szkielet)
#
# Baza: Universal Blue base-main (Fedora bootc + GNOME + kodeki/sterowniki już rozwiązane).
# Zamiast czystego quay.io/fedora/fedora-bootc = jedna zmiana tej linii.
FROM ghcr.io/ublue-os/base-main:latest

# ---------------------------------------------------------------------------
# OVERLAY SYSTEMOWY
# Pliki z katalogu files/ nakładamy na / obrazu.
# Struktura: files/usr/..., files/etc/... → /usr/..., /etc/...
# ---------------------------------------------------------------------------
COPY files/ /

# ---------------------------------------------------------------------------
# REBRANDING os-release
#
# Strategia: RUN + sed zamiast pliku overlay.
# Powód: /usr/lib/os-release w base-main to symlink → plik overlay go nie nadpisze
# poprawnie przez COPY (skopiuje do celu symlinku, ale kolejny upgrade UBlue
# może go przywrócić). Bezpieczniej: modyfikujemy go in-place przez sed.
# Zostawiamy pola upstream (VERSION_ID, VERSION, BUILD_ID) tak jak są —
# rebrandujemy tylko pola tożsamości dystrybucji.
# ---------------------------------------------------------------------------
RUN sed -i \
        -e 's|^NAME=.*|NAME="BoobsOS"|' \
        -e 's|^PRETTY_NAME=.*|PRETTY_NAME="BoobsOS (Fedora Linux)"|' \
        -e 's|^ID=.*|ID=boobsos|' \
        -e 's|^ID_LIKE=.*|ID_LIKE="fedora"|' \
        -e 's|^HOME_URL=.*|HOME_URL="https://boobsos.example.com"|' \
        -e 's|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL="https://boobsos.example.com/docs"|' \
        -e 's|^SUPPORT_URL=.*|SUPPORT_URL="https://boobsos.example.com/support"|' \
        -e 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://gitlab.example.com/boobsos/boobsos/-/issues"|' \
        /usr/lib/os-release \
    && grep -E '^(NAME|PRETTY_NAME|ID|ID_LIKE)' /usr/lib/os-release \
    && echo "os-release: rebranding OK"

# Dodaj VARIANT jeśli go nie ma (base-main może nie mieć VARIANT)
RUN grep -q '^VARIANT=' /usr/lib/os-release \
    || echo 'VARIANT="Desktop"' >> /usr/lib/os-release
RUN grep -q '^VARIANT_ID=' /usr/lib/os-release \
    || echo 'VARIANT_ID=desktop' >> /usr/lib/os-release

# ---------------------------------------------------------------------------
# F2: pakiety DevOps (podman, kubectl, helm, k9s, terraform, ansible, gh, glab,
#     zsh, starship, fastfetch, VSCode, distrobox, itd.)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# F3: branding w systemie (Plymouth, GDM, tapeta pulpitu, motyw GTK, fastfetch)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# LINT — obowiązkowy krok dla obrazów bootc
# Weryfikuje poprawność obrazu jako bootc-compatible OS container.
# ---------------------------------------------------------------------------
RUN bootc container lint
