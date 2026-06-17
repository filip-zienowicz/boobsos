# BoobsOS — Containerfile (Faza F1: minimalny szkielet)
#
# Baza: Universal Blue silverblue-main (Fedora Atomic + GNOME + kodeki/sterowniki).
# UWAGA: base-main jest HEADLESS (bez DE) — dla desktopu używamy silverblue-main,
# który zawiera pełne GNOME + GDM. KDE = kinoite-main. Zmiana = ta jedna linia.
FROM ghcr.io/ublue-os/silverblue-main:latest

# ---------------------------------------------------------------------------
# OVERLAY SYSTEMOWY
# Pliki z katalogu files/ nakładamy na / obrazu.
# Struktura: files/usr/..., files/etc/... → /usr/..., /etc/...
# ---------------------------------------------------------------------------
COPY files/ /

# Aktywuj zaufane CA (registry.gitlab.cycr.us + repo.cycx.io) z anchora
# files/etc/pki/ca-trust/source/anchors/cycr-us-ca.crt
RUN update-ca-trust 2>/dev/null || true

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
        -e 's|^PRETTY_NAME=.*|PRETTY_NAME="BoobsOS"|' \
        -e 's|^ID=.*|ID=boobsos|' \
        -e 's|^ID_LIKE=.*|ID_LIKE="fedora"|' \
        -e 's|^HOME_URL=.*|HOME_URL="https://boobsos.example.com"|' \
        -e 's|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL="https://boobsos.example.com/docs"|' \
        -e 's|^SUPPORT_URL=.*|SUPPORT_URL="https://boobsos.example.com/support"|' \
        -e 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://gitlab.example.com/boobsos/boobsos/-/issues"|' \
        -e 's|^CPE_NAME=.*|CPE_NAME="cpe:/o:boobsos:boobsos:44"|' \
        /usr/lib/os-release \
    && grep -E '^(NAME|PRETTY_NAME|ID|ID_LIKE)' /usr/lib/os-release \
    && echo "os-release: rebranding OK"
# CPE_NAME fallback — dodaj jeśli nie istniało w base image
RUN grep -q '^CPE_NAME=' /usr/lib/os-release \
    || echo 'CPE_NAME="cpe:/o:boobsos:boobsos:44"' >> /usr/lib/os-release

# Dodaj VARIANT jeśli go nie ma (base-main może nie mieć VARIANT)
RUN grep -q '^VARIANT=' /usr/lib/os-release \
    || echo 'VARIANT="Desktop"' >> /usr/lib/os-release
RUN grep -q '^VARIANT_ID=' /usr/lib/os-release \
    || echo 'VARIANT_ID=desktop' >> /usr/lib/os-release

# ---------------------------------------------------------------------------
# F2: pakiety DevOps + włączenie Flathub
#
# Repozytoria third-party nakładane przez overlay (COPY files/ / wyżej):
#   - files/etc/yum.repos.d/hashicorp.repo     → terraform, vault
#   - files/etc/yum.repos.d/docker-ce.repo     → docker-ce, docker-compose-plugin
#   - files/etc/yum.repos.d/kubernetes.repo    → kubectl (v1.31)
#   - files/etc/yum.repos.d/azure-cli.repo     → azure-cli
#   - files/etc/yum.repos.d/google-cloud-cli.repo → google-cloud-cli
#
# Pozostałe narzędzia spoza Fedora repo instalowane przez COPR lub binarki
# (oznaczone komentarzami poniżej).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# F2.1: Włączenie repozytoriów COPR
#
# Poniższe COPR są potrzebne dla pakietów niedostępnych w głównym Fedora repo:
#   - k9s:    yarn zawiera, ale preferujemy COPR dla aktualnych wersji
#   - lazygit: brak w Fedora repo → COPR: atim/lazygit
#   - glab:    GitLab CLI (glab) → dostępny w Fedora repo od F38 (verify!)
#   - eza:     nowoczesny ls, fork exa → dostępny w Fedora repo od F39
#   - zoxide:  smart cd → dostępny w Fedora repo
#   - starship: prompt → dostępny w Fedora repo
#   - mise:    narzędzie do zarządzania toolchainami (asdf-compatible)
#              → brak w Fedora repo → COPR: jdx/mise  # UWAGA: zweryfikować
#   - just:    command runner → dostępny w Fedora repo od F38
#   - sops:    secrets manager → brak w Fedora repo → binarka z GitHub releases
#   - age:     encryption → dostępny w Fedora repo
#   - opentofu: IaC (fork terraform) → COPR: opentofu/opentofu  # UWAGA: zweryfikować
# ---------------------------------------------------------------------------
# lazygit — TUI dla git; brak w Fedora repo → COPR atim/lazygit (zweryfikowane).
# mise i opentofu NIE wymagają COPR — są w Fedora 44 / przez własne repo (mise.repo).
RUN dnf copr enable -y atim/lazygit \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.2: Instalacja pakietów — Kontenery i runtime
#
# Pakiety z: docker-ce.repo (docker-ce*), Fedora repo (podman już w bazie UBlue)
# UWAGA: base-main (UBlue) zawiera już podman, buildah, skopeo, distrobox.
#        Nie reinstalujemy — instalujemy tylko docker-ce stack.
# UWAGA: docker-ce i podman mogą kolidować przez moby-engine/containerd.
#        Jeśli build się posypie — usuń docker-ce z listy i zostaw tylko podman.
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Docker CE (docker.repo) ---
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.3: Instalacja pakietów — Kubernetes i zarządzanie klastrem
#
# kubectl: kubernetes.repo (v1.31)
# helm: Fedora repo (dostępny od F36+)  # UWAGA: zweryfikować wersję
# k9s: Fedora repo (dostępny od F39)    # UWAGA: jeśli brak → COPR: luminoso/k9s
# kubectx/kubens: Fedora repo           # UWAGA: zweryfikować — mogą być jako kubectx
# kustomize: Fedora repo (kustomize)    # UWAGA: zweryfikować nazwę rpm
# stern: brak w Fedora repo → binarka z GitHub releases (TODO poniżej)
# kind: brak w Fedora repo → binarka z GitHub releases (TODO poniżej)
# ---------------------------------------------------------------------------
# Zweryfikowane w Fedora 44: helm (4.1.1), k9s (0.51), kustomize (5.8), kind (0.31).
# kubectl: z kubernetes.repo (v1.31). kubectx/kubens: brak w rpm → skrypty (F2.4).
RUN dnf install -y \
    # --- kubectl (kubernetes.repo v1.31) ---
    kubectl \
    # --- Helm — zarządzanie aplikacjami K8s (Fedora repo) ---
    helm \
    # --- k9s — TUI dla Kubernetes (Fedora repo) ---
    k9s \
    # --- kustomize — nakładki YAML dla K8s (Fedora repo) ---
    kustomize \
    && dnf clean all
# UWAGA: kind NIE jest instalowany z Fedora rpm — pakiet 'kind' wymaga
# (docker-cli OR podman-docker), które kolidują z prawdziwym docker-ce.
# Dlatego kind instalujemy jako binarkę w F2.4.

# ---------------------------------------------------------------------------
# F2.4: Narzędzia K8s niedostępne / niemożliwe w rpm (stern, kind, kubectx, kubens)
#
# stern — tail logów z wielu podów K8s. Brak rpm → binarka z GitHub releases.
# kind  — Kubernetes in Docker. Pakiet rpm wymaga (docker-cli OR podman-docker),
#         co koliduje z docker-ce → instalujemy binarkę z GitHub releases.
# kubectx/kubens — przełączanie kontekstów/namespace. Brak rpm → czyste skrypty
#                  bash (niezależne od architektury) wprost z repo ahmetb/kubectx.
# Instalujemy do /usr/bin — NIE /usr/local/bin! W bootc /usr/local to symlink
# do /var/usrlocal (poza obrazem), więc pliki tam nie przetrwają. /usr/bin jest
# częścią niezmiennego obrazu.
# UWAGA: wersje hardcode — aktualizuj przy nowym buildzie.
# ---------------------------------------------------------------------------
RUN STERN_VERSION="1.30.0" \
    && KIND_VERSION="0.31.0" \
    && KUBECTX_VERSION="0.9.5" \
    && ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
    # stern (binarka)
    && curl -fsSL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin stern \
    && chmod +x /usr/bin/stern \
    # kind (binarka)
    && curl -fsSL "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH}" \
       -o /usr/bin/kind \
    && chmod +x /usr/bin/kind \
    # kubectx + kubens (skrypty bash)
    && curl -fsSL "https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_VERSION}/kubectx" \
       -o /usr/bin/kubectx \
    && curl -fsSL "https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_VERSION}/kubens" \
       -o /usr/bin/kubens \
    && chmod +x /usr/bin/kubectx /usr/bin/kubens \
    && echo "stern $(stern --version 2>/dev/null || echo 'installed'), kubectx/kubens installed"

# ---------------------------------------------------------------------------
# F2.5: Instalacja pakietów — IaC i automatyzacja
#
# terraform: hashicorp.repo
# opentofu:  COPR opentofu/opentofu (włączony wyżej)  # UWAGA: zweryfikować
# ansible:   Fedora repo (ansible-core lub ansible — zweryfikuj)
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Terraform (HashiCorp repo) ---
    terraform \
    # --- OpenTofu — open-source fork Terraform (Fedora repo, opentofu 1.11) ---
    opentofu \
    # --- Ansible — automatyzacja konfiguracji ---
    # ansible-core = minimalna instalacja; 'ansible' = pełna kolekcja (duża)
    ansible-core \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.6: Instalacja pakietów — Narzędzia sieciowe
#
# Wszystkie dostępne w Fedora repo. Nazwy zweryfikowane:
#   httpie: 'httpie' (Fedora repo)  # UWAGA: zweryfikować — może być pip-only
#   iperf3: 'iperf3'
#   mtr: 'mtr'
#   nmap-ncat: 'nmap-ncat' (netcat przez nmap)
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Diagnostyka sieci ---
    nmap \
    nmap-ncat \
    tcpdump \
    mtr \
    bind-utils \
    whois \
    iperf3 \
    socat \
    traceroute \
    ethtool \
    iftop \
    # --- Transfer i tunel ---
    rsync \
    openssh-clients \
    sshpass \
    wireguard-tools \
    # --- HTTP/REST ---
    # UWAGA: httpie — dostępny w Fedora repo jako 'httpie'; jeśli brak → pip install httpie
    httpie \
    # --- Analiza pakietów ---
    # wireshark-cli = tshark (terminalowa wersja Wireshark), bez GUI
    wireshark-cli \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.7: Instalacja pakietów — Shell, terminal i Git
#
# gh (GitHub CLI): Fedora repo (dostępny od F36)
# glab (GitLab CLI): Fedora repo (dostępny od F38)  # UWAGA: zweryfikować
# git-lfs: Fedora repo
# tmux: Fedora repo
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Shell ---
    zsh \
    tmux \
    # --- Git i hosting ---
    git \
    git-lfs \
    gh \
    # UWAGA: glab — GitLab CLI; zweryfikuj czy jest w Fedora repo (może być 'glab')
    glab \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.8: Instalacja pakietów — CLI UX i narzędzia deweloperskie
#
# eza: nowoczesny 'ls' (fork exa); Fedora repo od F39  # UWAGA: zweryfikować
# bat: 'cat' z podświetlaniem składni; Fedora repo
# fd-find: szybki 'find'; w Fedora repo jako 'fd-find'  # UWAGA: może być 'fd'
# ripgrep: szybki grep; Fedora repo jako 'ripgrep'
# fzf: fuzzy finder; Fedora repo
# zoxide: smart cd; Fedora repo  # UWAGA: zweryfikować
# git-delta: diff pager; Fedora repo jako 'git-delta'  # UWAGA: może być 'delta'
# lazygit: TUI dla git; COPR atim/lazygit (włączony wyżej)
# starship: prompt; BRAK w Fedora repo → skrypt instalacyjny (F2.8b poniżej)
# just: command runner; Fedora repo (1.51) — zweryfikowane
# fastfetch: system info; Fedora repo (2.63) — zweryfikowane
# direnv: env per katalog; Fedora repo
# btop: TUI monitor zasobów; Fedora repo
# ncdu: analiza dysku; Fedora repo
# yq: YAML processor; Fedora repo (4.47 = mikefarah/Go) — zweryfikowane
# mise: toolchain manager; własne repo mise.repo (mise.jdx.dev) — zweryfikowane
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Przegląd plików i nawigacja ---
    # UWAGA: eza — zweryfikować nazwę w Fedora repo (może być 'eza')
    eza \
    bat \
    # UWAGA: fd-find — w Fedora repo jako 'fd-find' lub 'fd'; sprawdź 'dnf info fd-find'
    fd-find \
    tree \
    ncdu \
    fzf \
    zoxide \
    direnv \
    # --- Wyszukiwanie i diff ---
    ripgrep \
    # UWAGA: git-delta — Fedora repo; zweryfikuj nazwę pakietu ('git-delta' lub 'delta')
    git-delta \
    lazygit \
    # --- Monitorowanie systemu ---
    htop \
    btop \
    # --- JSON/YAML ---
    jq \
    # UWAGA: yq — YAML processor; dostępny w Fedora repo jako 'yq' (python-yq) lub 'go-yq'
    # Dwie różne implementacje: python-yq (wrapper jq) i mikefarah/yq (Go).
    # Rekomendacja: go-yq lub binarka z GitHub; tutaj próbujemy Fedora repo
    yq \
    # --- Automatyzacja i build ---
    just \
    # --- Toolchain manager (mise — z własnego repo files/etc/yum.repos.d/mise.repo) ---
    mise \
    # --- System info ---
    # UWAGA: fastfetch — Fedora repo od F39+; zweryfikować
    fastfetch \
    # --- Edytor ---
    neovim \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.8b: starship — prompt (brak w Fedora repo)
# Oficjalny skrypt instalacyjny; sam wykrywa architekturę i pobiera binarkę.
# Instaluje do /usr/bin (trwałe w obrazie bootc).
# ---------------------------------------------------------------------------
RUN curl -fsSL https://starship.rs/install.sh \
    | sh -s -- --yes --bin-dir /usr/bin \
    && starship --version

# ---------------------------------------------------------------------------
# F2.9: Instalacja pakietów — Sekrety i kryptografia
#
# vault: hashicorp.repo
# sops: brak w Fedora repo → binarka z GitHub releases (poniżej)
# age: Fedora repo  # UWAGA: zweryfikować — może być jako 'age'
# gnupg2: Fedora repo (zwykle już zainstalowany w bazie)
# pass: Fedora repo
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- HashiCorp Vault ---
    vault \
    # --- Kryptografia i sekrety (zweryfikowane w Fedora 44) ---
    age \
    gnupg2 \
    pass \
    # pcsc-lite: runtime dla age-plugin-yubikey (komunikacja z YubiKey przez PIV)
    pcsc-lite \
    && dnf clean all

# sops — Mozilla SOPS; brak rpm w Fedora repo → binarka z GitHub releases
# age-plugin-yubikey — brak w Fedora 44 → binarka z GitHub releases (str4d)
# UWAGA: wersje hardcode — aktualizuj przy nowym buildzie
RUN SOPS_VERSION="3.9.1" \
    && AGEYK_VERSION="0.5.0" \
    && ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
    && RAWARCH="$(uname -m)" \
    # sops
    && curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" \
       -o /usr/bin/sops \
    && chmod +x /usr/bin/sops \
    # age-plugin-yubikey (tarball zawiera katalog age-plugin-yubikey/age-plugin-yubikey)
    && curl -fsSL "https://github.com/str4d/age-plugin-yubikey/releases/download/v${AGEYK_VERSION}/age-plugin-yubikey-v${AGEYK_VERSION}-${RAWARCH}-linux.tar.gz" \
       | tar -xzf - -C /usr/bin --strip-components=1 age-plugin-yubikey/age-plugin-yubikey \
    && chmod +x /usr/bin/age-plugin-yubikey \
    && echo "sops $(sops --version 2>/dev/null | head -1 || echo ok), age-plugin-yubikey installed"

# ---------------------------------------------------------------------------
# F2.10: Instalacja pakietów — Build i języki
#
# @development-tools: meta-pakiet Fedora (gcc, make, autoconf, etc.)
# golang: Fedora repo
# mise: zainstalowane wyżej przez COPR (zarządza node, python, ruby, etc.)
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Kompilator i toolchain C/C++ ---
    '@development-tools' \
    # --- Go ---
    golang \
    # --- Python (dev headers, pip) — dla ansible i innych narzędzi ---
    python3-pip \
    python3-devel \
    # --- unzip — wymagany przez instalator AWS CLI v2 (F2.11) ---
    unzip \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.11: Instalacja pakietów — Chmura (AWS, Azure, Google Cloud)
#
# awscli2: brak jako rpm w Fedora repo → oficjalny installer AWS CLI v2
#           UWAGA: AWS nie dostarcza rpm; instalacja przez oficjalny bundle
# azure-cli: azure-cli.repo (Microsoft)
# google-cloud-cli: google-cloud-cli.repo (Google)
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Azure CLI (Microsoft repo) ---
    azure-cli \
    # --- Google Cloud CLI (Google repo) ---
    # UWAGA: google-cloud-cli.repo używa baseurl el9 x86_64; na aarch64 może nie działać
    google-cloud-cli \
    && dnf clean all

# AWS CLI v2 — brak rpm; instalacja przez oficjalny bundle AWS
# Źródło: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# UWAGA bootc: /usr/local i /opt to symlinki do /var (poza obrazem) — instalujemy
#        do /usr/libexec/aws-cli, a symlinki binarek do /usr/bin.
RUN ARCH="$(uname -m)" \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp/awscli \
    && /tmp/awscli/aws/install --bin-dir /usr/bin --install-dir /usr/libexec/aws-cli \
    && rm -rf /tmp/awscliv2.zip /tmp/awscli \
    && aws --version

# ---------------------------------------------------------------------------
# F2.12: Konfiguracja systemu — grupy i usługi
# ---------------------------------------------------------------------------

# Utwórz grupę 'docker' (docker-ce powinien to zrobić, ale upewniamy się)
# Użytkownicy muszą być dodani do grupy 'docker' po instalacji przez: usermod -aG docker $USER
RUN groupadd -f docker

# Upewnij się że narzędzie do przełączania edycji jest wykonywalne (idempotentne)
RUN chmod +x /usr/bin/boobsos-edition

# Włącz socket Dockera (preferowane nad docker.service — lazy start)
# UWAGA: W obrazach bootc używamy 'systemctl enable' (preset), nie 'start'.
# docker.socket uruchamia docker.service na żądanie (lazy).
RUN systemctl enable docker.socket

# Włącz socket Podmana (już może być w bazie UBlue, ale upewniamy się)
RUN systemctl enable podman.socket

# ---------------------------------------------------------------------------
# F2.13: Włączenie Flathub (systemowy remote Flatpak)
#
# NIE instalujemy flatpaków w obrazie — tylko rejestrujemy Flathub jako remote.
# Aplikacje GUI instaluje użytkownik po zalogowaniu, np.:
#   flatpak install flathub com.visualstudio.code    # VSCode
#   flatpak install flathub com.spotify.Client       # Spotify
#   flatpak install flathub org.mozilla.firefox      # Firefox
#   flatpak install flathub com.slack.Slack          # Slack
#
# Metoda DEKLARATYWNA (bootc-native): plik
#   files/etc/flatpak/remotes.d/flathub.flatpakrepo
# (prawdziwy flatpakrepo z wbudowanym kluczem GPG) jest nakładany przez COPY.
# flatpak automatycznie rejestruje remote z /etc/flatpak/remotes.d/*.flatpakrepo —
# bez potrzeby 'flatpak remote-add' i bez sieci w czasie buildu.
# UWAGA: NIE używać tu komentarza-placeholdera — flatpak parsuje każdy plik
#        w remotes.d i nieprawidłowy plik wywala operacje flatpak.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# F3: branding w systemie
#
# Pliki nakładane przez COPY files/ / (wcześniej w tym Containerfile):
#   files/usr/share/backgrounds/boobsos/boobsos.png        — tapeta (3840x2160)
#   files/usr/share/backgrounds/boobsos/boobsos-dark.png   — tapeta ciemna
#   files/etc/dconf/profile/user                           — profil dconf użytkownika
#   files/etc/dconf/db/local.d/00-boobsos                  — ustawienia GNOME system-wide
#   files/etc/dconf/db/gdm.d/01-boobsos                    — ustawienia GDM (logo)
#   files/usr/share/pixmaps/boobsos-gdm-logo.png           — logo dla GDM
#   files/usr/share/plymouth/themes/boobsos/               — motyw Plymouth
#   files/etc/fastfetch/config.jsonc                       — konfiguracja fastfetch
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# F3.1: Rozszerzenia GNOME Shell — tradycyjny desktop (taskbar na dole + tray)
#
# Zweryfikowane pakiety w Fedora 44 / silverblue-main:
#   gnome-shell-extension-dash-to-panel v73  — pasek zadań na dole (zastępuje dock)
#   gnome-shell-extension-appindicator v64   — ikony zasobnika systemowego (tray)
#
# UUID rozszerzeń (zweryfikowane przez ls /usr/share/gnome-shell/extensions/
#   w kontenerze bazy po dnf install):
#   dash-to-panel@jderose9.github.com
#   appindicatorsupport@rgcjonas.gmail.com
#
# POMINIĘTE (brak w Fedora 44 repo):
#   gnome-shell-extension-arc-menu — nie istnieje jako rpm; można doinstalować
#   przez użytkownika z extensions.gnome.org lub Flathub (Extension Manager)
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # Taskbar na dole — tradycyjny układ pulpitu (nie macowy)
    gnome-shell-extension-dash-to-panel \
    # Ikony zasobnika (system tray) — AppIndicator/KStatusNotifierItem
    gnome-shell-extension-appindicator \
    && dnf clean all

# ---------------------------------------------------------------------------
# F3.2: Plymouth — motyw startowy BoobsOS
#
# Motyw 'boobsos' używa modułu two-step (dostępny w bazie silverblue-main).
# ImageDir wskazuje na /usr/share/plymouth/themes/spinner (zawiera animację).
# Nasze watermark.png (logo BoobsOS) nadpisuje watermark.png ze spinnera.
# Tło: ciemny granat #080F1A, pasek postępu w kolorze marki (#2563EB).
#
# UWAGA: plymouth-set-default-theme bez flagi -R (--rebuild-initrd) —
# rebuild initrd nie zadziała w kontenerze; initrd przebudowuje się
# automatycznie przy pierwszym bootc upgrade/install na systemie docelowym.
# ---------------------------------------------------------------------------
# Skopiuj nasze watermark.png jako logo motywu (nadpisuje spinner watermark)
RUN cp /usr/share/plymouth/themes/boobsos/watermark.png \
       /usr/share/plymouth/themes/spinner/watermark.png

# Ustaw motyw BoobsOS jako domyślny
# Jeśli plymouth-set-default-theme zawiedzie, fallback do pliku conf
RUN plymouth-set-default-theme boobsos \
    || { mkdir -p /etc/plymouth \
         && printf '[Daemon]\nTheme=boobsos\n' > /etc/plymouth/plymouthd.conf; } \
    && echo "Plymouth theme: boobsos (OK)"

# ---------------------------------------------------------------------------
# F3.3: dconf — aktualizacja systemowej bazy kluczy
#
# Aktywuje pliki z etc/dconf/db/local.d/ i etc/dconf/db/gdm.d/.
# Musi być po COPY files/ i instalacji rozszerzeń.
# ---------------------------------------------------------------------------
RUN dconf update \
    && echo "dconf update: OK"

# ---------------------------------------------------------------------------
# F3.4: os-release — dodanie pól brandingowych ANSI i LOGO
#
# ANSI_COLOR: ANSI escape dla 'Brand Blue' #2563EB (RGB: 37,99,235)
# LOGO: identyfikator logo dla systemd i innych narzędzi
# Rozszerzamy istniejący sed z F1 — dodajemy brakujące pola jeśli ich nie ma.
# ---------------------------------------------------------------------------
RUN grep -q '^ANSI_COLOR=' /usr/lib/os-release \
    || echo 'ANSI_COLOR="38;2;37;99;235"' >> /usr/lib/os-release
RUN grep -q '^LOGO=' /usr/lib/os-release \
    || echo 'LOGO=boobsos' >> /usr/lib/os-release

# ---------------------------------------------------------------------------
# F3.5: ikona logo dystrybucji (LOGO=boobsos)
#
# Logo BoobsOS jako ikona motywu 'boobsos' (z files/usr/share/icons/hicolor/).
# Dzięki temu GNOME pokazuje je tam, gdzie używa LOGO z os-release:
# gnome-tour (ekran powitalny), Ustawienia → Informacje, ekran logowania.
# Odświeżamy cache motywu hicolor.
# ---------------------------------------------------------------------------
RUN gtk4-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null \
    || gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null \
    || true

# ---------------------------------------------------------------------------
# F2.14: Aplikacje desktop + baseline bezpieczeństwa
#
# Dodane w tej sekcji:
#   A) VS Code (rpm, Microsoft repo) — edytor kodu gotowy od razu po instalacji
#   B) openconnect + NetworkManager-openconnect{,-gnome} — VPN (Cisco AnyConnect/GlobalProtect)
#   C) torbrowser-launcher — launcher pobierający i weryfikujący Tor Browser przy
#      pierwszym uruchomieniu (standardowy sposób dla Fedory; pakiet z Fedora repo)
#   D) OnlyOffice Desktop Editors — flatpak z Flathub, instalowany przy
#      pierwszym boocie przez usługę systemd (patrz niżej)
#   E) firewalld — zapora sieciowa; w bazie silverblue-main JUŻ zainstalowana i
#      włączona (preset enabled). Zostaw domyślną strefę FedoraWorkstation (pozwala
#      na SSH i porty > 1024 — sensowny default). `systemctl enable` to idemopotent.
#   F) auditd — audyt systemu; w bazie silverblue-main JUŻ zainstalowany i włączony.
#      Włączamy explicite na wypadek gdyby baza zmieniła preset.
#   G) logrotate — rotacja logów; w bazie silverblue-main JUŻ zainstalowany i włączony
#      (timer enabled). Polityka dystrybucji: files/etc/logrotate.d/boobsos.
#
# UWAGA WireGuard: wireguard-tools zainstalowany w F2.6. NetworkManager ma natywne
# wsparcie WireGuard (nm-applet + nmcli) — nie potrzeba dodatkowego pakietu.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# F2.14a: VS Code — edytor kodu (repo Microsoft)
#
# Repo: files/etc/yum.repos.d/vscode.repo (nakładane przez COPY files/ / wyżej).
# Klucz GPG importujemy przed dnf install — bez tego dnf odmówi instalacji
# ze względu na gpgcheck=1 w vscode.repo (pakiet podpisany kluczem Microsoft).
# ---------------------------------------------------------------------------
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && echo "VS Code GPG key: OK"

RUN dnf install -y \
    # VS Code — edytor kodu (Microsoft repo, vscode.repo)
    code \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.14b: openconnect — klient VPN (Cisco AnyConnect / GlobalProtect / Pulse)
#
# openconnect: klient CLI (Fedora repo, już zainstalowany w bazie silverblue)
# NetworkManager-openconnect: integracja z NetworkManager (ikona VPN w GNOME)
# NetworkManager-openconnect-gnome: aplet GNOME do konfiguracji VPN przez GUI
# Uwaga: te pakiety są już w bazie silverblue-main — install jest idempotentny.
# ---------------------------------------------------------------------------
RUN dnf install -y \
    openconnect \
    NetworkManager-openconnect \
    NetworkManager-openconnect-gnome \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.14c: Tor Browser Launcher
#
# torbrowser-launcher — launcher z Fedora repo (Fedora 44: wersja 0.3.9).
# Nie bundluje samego Tor Browser w rpm; pobiera i weryfikuje go kryptograficznie
# przy pierwszym uruchomieniu użytkownika. To standardowa i rekomendowana metoda
# dla Fedory (nie trzeba ufać zewnętrznym binarkom w obrazie OCI).
# ---------------------------------------------------------------------------
RUN dnf install -y \
    torbrowser-launcher \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.14d: OnlyOffice — instalacja flatpaka przy pierwszym boocie
#
# OnlyOffice Desktop Editors nie ma dobrego rpm dla Fedory → flatpak z Flathub.
# NIE instalujemy w czasie buildu obrazu (wymaga sieci i Flathub remote).
# Zamiast tego: usługa systemd oneshot uruchamia się przy pierwszym boocie,
# gdy sieć jest dostępna, instaluje flatpaki i tworzy stamp (nie startuje ponownie).
#
# Pliki (nakładane przez COPY files/ / wyżej):
#   files/etc/systemd/system/boobsos-firstboot-flatpaks.service
#   files/usr/libexec/boobsos-install-flatpaks  (skrypt, lista flatpaków na górze)
#
# Aby dodać kolejne flatpaki (Spotify, Slack, ...):
#   dopisz ID do tablicy FLATPAKS w files/usr/libexec/boobsos-install-flatpaks
# ---------------------------------------------------------------------------
RUN systemctl enable boobsos-firstboot-flatpaks.service

# ---------------------------------------------------------------------------
# F2.14e: Baseline bezpieczeństwa — firewalld, auditd, logrotate
#
# Uwaga: wszystkie trzy pakiety są w bazie silverblue-main JUŻ zainstalowane
# i już z domyślnym presetem enabled. `systemctl enable` poniżej jest
# idempotentny — upewnia się że zostanie włączone nawet jeśli baza to zmieni.
#
# firewalld: strefa domyślna FedoraWorkstation (SSH + porty >1024 dozwolone).
#   NIE zmieniamy strefy agresywnie — sensowny default dla stacji roboczej.
# auditd: audyt syscalli, loguje do /var/log/audit/audit.log.
# logrotate.timer: timer systemd rotujący logi (cotygodniowy; compress; 7 cykli).
#   Polityka BoobsOS: files/etc/logrotate.d/boobsos (nakładana przez COPY).
# ---------------------------------------------------------------------------
RUN systemctl enable firewalld.service \
    && systemctl enable auditd.service \
    && systemctl enable logrotate.timer \
    && echo "Usługi bezpieczeństwa: firewalld auditd logrotate.timer — enabled"

# ---------------------------------------------------------------------------
# Auto-aktualizacje BoobsOS (bootc)
#
# Timer bootc co jakiś czas sprawdza rejestr, z którego zainstalowano system
# (origin = registry.gitlab.cycr.us/fzienowicz/boobsos), pobiera nowy obraz
# BoobsOS i stosuje go atomowo przy następnym restarcie. To AKTUALIZACJE BoobsOS,
# nie Fedory — Fedora to tylko baza zapieczona w naszym obrazie.
# W bazie timer jest 'disabled' — włączamy go, by użytkownicy dostawali update'y.
# ---------------------------------------------------------------------------
RUN systemctl enable bootc-fetch-apply-updates.timer \
    && echo "bootc auto-update timer — enabled"

# ---------------------------------------------------------------------------
# F2.15: Domyślne configi (neovim + oh-my-zsh)
#
# Cel: każdy nowy użytkownik tworzony przez useradd -m (np. 'boobs' w
# Containerfile.vm) dostaje gotowe dotfiles z /etc/skel out-of-the-box.
#
# Co nakładamy przez COPY files/ / (wykonany wcześniej na początku Containerfile):
#   files/etc/skel/.config/nvim/init.lua  — config neovim (lazy.nvim bootstrap,
#       LSP/mason/treesitter/telescope). Pluginy + LSP instalują się przy 1. starcie.
#   files/etc/skel/.zshrc                 — config zsh (oh-my-zsh, theme ys,
#       plugins: git zsh-autosuggestions zsh-syntax-highlighting, aliasy ls/bat)
#
# Oh-my-zsh framework + pluginy: klonujemy do /etc/skel/.oh-my-zsh w buildzie,
# bo skrypt instalacyjny wymaga sieci i runtime usera. useradd -m skopiuje
# cały katalog .oh-my-zsh do $HOME nowego usera. .zshrc odwołuje się do
# $HOME/.oh-my-zsh — działa po skopiowaniu bez żadnych zmian.
#
# Katalogi .git usuwamy (slim — nie potrzebujemy historii w obrazie produkcyjnym).
#
# nodejs22 + nodejs22-npm: wymagane przez Mason (instalator LSP-ów przez npm).
# Fedora 44 nie ma generycznych pakietów 'nodejs'/'npm' — używamy nodejs22
# (LTS aktywne; nodejs20 i nodejs24 też dostępne, ale 22 = current LTS w F44).
# gcc/make/python3-pip: już w obrazie (F2.10 @development-tools + python3-pip).
# ripgrep/fd-find: już w obrazie (F2.8).
# ---------------------------------------------------------------------------
RUN dnf install -y \
    nodejs22 \
    nodejs22-npm \
    && dnf clean all

RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh /etc/skel/.oh-my-zsh \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
       /etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
       /etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    # Usuń katalogi .git (slim — oszczędność miejsca, niezbędne tylko przy aktualizacji)
    && find /etc/skel/.oh-my-zsh -name .git -type d -prune -exec rm -rf {} + \
    # Upewnij się że /etc/skel jest czytelny dla wszystkich (standardowe uprawnienia)
    && chmod -R a+rX /etc/skel \
    && echo "oh-my-zsh + plugins: OK" \
    && echo "skel files:" && find /etc/skel -type f | sort

# ---------------------------------------------------------------------------
# F4.1: Google Chrome + Brave Browser
#
# Repozytoria third-party:
#   files/etc/yum.repos.d/google-chrome.repo  → Google Chrome Stable
#   files/etc/yum.repos.d/brave-browser.repo  → Brave Browser
# (nakładane przez COPY files/ / na początku Containerfile)
#
# Desktop ID po instalacji (zweryfikowane przez dnf repoquery --list):
#   google-chrome → /usr/share/applications/google-chrome.desktop
#                   /usr/share/applications/com.google.Chrome.desktop
#   brave-browser → /usr/share/applications/brave-browser.desktop
#                   /usr/share/applications/com.brave.Browser.desktop
#
# Pasek zadań: Brave JEST przypięty (patrz F4.3 dconf); Chrome jest zainstalowany
# ale NIE przypięty. Firefox jest zainstalowany ale NIE przypięty.
#
# Dry-run (dnf --assumeno) zweryfikowany:
#   google-chrome-stable 149.0.7827.114-1  → OK
#   brave-browser 1.91.172-1               → OK (+ brave-keyring dep)
# ---------------------------------------------------------------------------
# UWAGA bootc: Chrome i Brave instalują się do /opt, a w obrazie atomic
# /opt to symlink → /var/opt (poza obrazem), więc rpm nie rozpakuje (cpio mkdir fail).
# Zamieniamy symlink /opt na REALNY katalog w obrazie (wzorzec Bazzite/ublue) —
# ostree przy wdrożeniu zrelokuje zawartość /opt do /var/opt. Robimy to RAZ,
# przed instalacją obu przeglądarek.
RUN rm -f /opt && mkdir -p /opt

RUN rpm --import https://dl.google.com/linux/linux_signing_key.pub \
    && echo "Google Chrome GPG key: OK"

RUN dnf install -y \
    google-chrome-stable \
    && dnf clean all

RUN rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc \
    && echo "Brave Browser GPG key: OK"

RUN dnf install -y \
    brave-browser \
    && dnf clean all

# ---------------------------------------------------------------------------
# F4.2: Narzędzia sieciowe i kryptograficzne — hping3 + hashcat
#
# hping3:  generator/analizator pakietów TCP/IP; Fedora repo (fedora, v0.0.20051105)
# hashcat: GPU password cracker;               Fedora repo (fedora, v7.1.2)
# Oba dostępne w standardowym Fedora 44 repo — bez RPM Fusion.
#
# Dry-run (dnf info w kontenerze bazy, zweryfikowane):
#   hping3  v0.0.20051105  → repo: fedora  OK
#   hashcat v7.1.2         → repo: fedora  OK
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Diagnostyka / testowanie sieci (TCP/IP packet crafting) ---
    hping3 \
    # --- Password recovery / audyt haseł (GPU-accelerated) ---
    hashcat \
    && dnf clean all

# ---------------------------------------------------------------------------
# F4.3: dconf — aktualizacja po dodaniu nowych ustawień
#
# Uruchamiamy dconf update ponownie po F4, by wbudować nowe klucze dconf
# (favorite-apps z Brave) do bazy systemowej.
# ---------------------------------------------------------------------------
RUN dconf update \
    && echo "dconf update F4: OK"

# ---------------------------------------------------------------------------
# F4.4: ekran powitalny — POMINIĘTE (rozwiązane inaczej)
#
# „Welcome to BoobsOS + Take Tour/Skip" z balonem to DIALOG POWITALNY GNOME SHELL
# (welcome-dialog), a NIE gnome-tour. Jego grafika jest zaszyta w zasobach
# gnome-shell. Zamiast kruchej podmiany gresource shella — wyłączamy ten
# jednorazowy dialog przez dconf: org/gnome/shell welcome-dialog-last-shown-version
# (patrz files/etc/dconf/db/local.d/00-boobsos). gnome-tour zostaje bez zmian.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# F2.16: Rozszerzony toolchain DevOps/SRE/security — pakiety RPM
#
# Wszystkie zweryfikowane w Fedora 44 (dnf list w kontenerze bazy):
#
#   ansible-lint (python3-ansible-lint):
#     Statyczny linter playbooków Ansible — niezbędny przy CI/CD dla IaC.
#     Pakiet RPM = python3-ansible-lint (v26.4), dostarcza /usr/bin/ansible-lint.
#
#   yamllint:
#     Linter YAML — wymagany przy Ansible, Kubernetes manifests, Helm values.
#     Dostępny jako 'yamllint' (v1.38) w Fedora repo.
#
#   ShellCheck:
#     Statyczna analiza skryptów bash/sh — łapie typowe błędy. Fedora repo
#     (pakiet: ShellCheck — uwaga wielka litera, v0.11.0).
#
#   jc:
#     Konwertuje output CLI (ls, ps, dig, netstat…) na JSON — przydatny w
#     skryptach i pipeline'ach DevOps. Fedora repo (v1.25.6).
#
#   postgresql (klient psql):
#     Klient SQL dla PostgreSQL (psql, pg_dump…). W Fedora: pakiet 'postgresql'
#     to jest właśnie klient (v18). Niezbędny SRE — debugowanie DB.
#
#   mariadb (klient mysql):
#     Klient SQL kompatybilny z MySQL i MariaDB (mysql, mariadb, mysqldump).
#     Fedora repo: pakiet 'mariadb' (v11.8) — sam klient bez serwera.
#
#   valkey (redis-cli replacement):
#     Redis był usunięty z Fedora; valkey to oficjalny fork (v9.0) — dostarcza
#     'valkey-cli' (w pełni kompatybilny z redis-cli). SRE: debug cache/kolejki.
#
#   packer:
#     HashiCorp Packer — budowanie obrazów maszyn (AMI, Vagrant, QEMU…).
#     Dostępny z hashicorp.repo (pre-configured w files/ overlay) v1.15.
#
# Dry-run zweryfikowany w kontenerze bazy (silverblue-main:latest):
#   yamllint 1.38.0, ShellCheck 0.11.0, jc 1.25.6, postgresql 18.3,
#   mariadb 11.8.6, valkey 9.0.4, python3-ansible-lint 26.4.0 — wszystkie OK.
#   packer: dostępny przez hashicorp.repo (wbudowany w overlay).
# ---------------------------------------------------------------------------
RUN dnf install -y \
    # --- Linting i analiza kodu ---
    # Linter playbooków Ansible (python3-ansible-lint → /usr/bin/ansible-lint)
    python3-ansible-lint \
    # Linter YAML — manifesty K8s, Helm values, Ansible playbooks
    yamllint \
    # Statyczna analiza skryptów bash/sh (uwaga: pakiet to 'ShellCheck')
    ShellCheck \
    # Konwersja output CLI → JSON (jq-friendly pipeline)
    jc \
    # --- Klienty baz danych (SRE: debug i migracje) ---
    # Klient PostgreSQL (psql, pg_dump, pg_restore) — wersja 18
    postgresql \
    # Klient MySQL/MariaDB (mysql, mariadb, mysqldump) — bez serwera
    mariadb \
    # valkey-cli (drop-in replacement dla redis-cli; Redis usunięty z Fedora)
    valkey \
    # --- IaC — HashiCorp Packer (hashicorp.repo, pre-skonfigurowane w overlay) ---
    packer \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.17: Rozszerzony toolchain DevOps/SRE/security — binarki z GitHub releases
#
# Instalowane do /usr/bin (NIE /usr/local/bin — w bootc to symlink do /var).
# Wersje pinowane; ARCH wykrywany runtime (amd64/arm64).
# Wszystkie URLe zweryfikowane curl -fsIL → HTTP 200.
#
# Narzędzia:
#   kubeseal (v0.29.0)   — CLI dla Bitnami Sealed Secrets; szyfruje Secrets K8s
#                          kluczem klaster-publicznym → bezpieczne repo GitOps.
#   helmfile (v1.5.5)    — Deklaratywne zarządzanie wieloma Helm chart'ami naraz;
#                          odpowiednik docker-compose dla K8s.
#   k3d (v5.8.3)         — Lokalny klaster K3s w Dockerze; szybszy niż kind dla dev.
#   argocd (v2.14.4)     — CLI ArgoCD; GitOps controller dla K8s. Binarka bez dep.
#   flux (v2.5.1)        — CLI FluxCD; GitOps alternatywa dla ArgoCD.
#   cosign (v2.5.0)      — Podpisywanie i weryfikacja obrazów OCI (supply-chain sec).
#   trivy (v0.70.0)      — Skaner podatności obrazów/FS/IaC (Aqua Security).
#   syft (v1.26.1)       — Generowanie SBOM (Software Bill of Materials) z obrazów OCI.
#   grype (v0.90.0)      — Skaner podatności na podstawie SBOM (Anchore); para z syft.
#   terraform-docs       — Generowanie README.md z modułów Terraform (v0.20.0).
#   tflint (v0.63.0)     — Linter Terraform; łapie błędy przed planem/apply.
#   terragrunt (v1.0.8)  — DRY wrapper dla Terraform; zarządza stanem i modułami.
#   dive (v0.13.0)       — Interaktywna analiza warstw obrazu Docker (rozmiar, diff).
#   ctop (v0.7.7)        — top/htop dla kontenerów Docker — metryki w terminalu.
#   lazydocker (v0.23.3) — TUI dla Dockera (kontenery, obrazy, logi) — jak lazygit.
#
# Uwaga: trivy arm64 = Linux-ARM64 (nie arm64), amd64 = Linux-64bit.
# ---------------------------------------------------------------------------
RUN KUBESEAL_VERSION="0.29.0" \
    && HELMFILE_VERSION="1.5.5" \
    && K3D_VERSION="5.8.3" \
    && ARGOCD_VERSION="2.14.4" \
    && FLUX_VERSION="2.5.1" \
    && COSIGN_VERSION="2.5.0" \
    && TRIVY_VERSION="0.70.0" \
    && SYFT_VERSION="1.26.1" \
    && GRYPE_VERSION="0.90.0" \
    && TFDOCS_VERSION="0.20.0" \
    && TFLINT_VERSION="0.63.0" \
    && TERRAGRUNT_VERSION="1.0.8" \
    && DIVE_VERSION="0.13.0" \
    && CTOP_VERSION="0.7.7" \
    && LAZYDOCKER_VERSION="0.23.3" \
    && ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
    && TRIVY_ARCH="$(uname -m | sed 's/x86_64/64bit/;s/aarch64/ARM64/')" \
    # --- kubeseal — sealed-secrets CLI (tarball) ---
    && curl -fsSL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin kubeseal \
    && chmod +x /usr/bin/kubeseal \
    # --- helmfile — deklaratywne zarządzanie Helm (tarball) ---
    && curl -fsSL "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin helmfile \
    && chmod +x /usr/bin/helmfile \
    # --- k3d — lokalny klaster K3s w Dockerze (binarka) ---
    && curl -fsSL "https://github.com/k3d-io/k3d/releases/download/v${K3D_VERSION}/k3d-linux-${ARCH}" \
       -o /usr/bin/k3d \
    && chmod +x /usr/bin/k3d \
    # --- argocd CLI — GitOps controller (binarka) ---
    && curl -fsSL "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-${ARCH}" \
       -o /usr/bin/argocd \
    && chmod +x /usr/bin/argocd \
    # --- flux CLI — FluxCD GitOps (tarball) ---
    && curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin flux \
    && chmod +x /usr/bin/flux \
    # --- cosign — podpisywanie obrazów OCI / supply-chain (binarka) ---
    && curl -fsSL "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${ARCH}" \
       -o /usr/bin/cosign \
    && chmod +x /usr/bin/cosign \
    # --- trivy — skaner podatności obrazów/FS/IaC (tarball) ---
    # Uwaga: trivy używa niestandardowych nazw arch: 64bit / ARM64
    && curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin trivy \
    && chmod +x /usr/bin/trivy \
    # --- syft — generowanie SBOM z obrazów OCI (tarball) ---
    && curl -fsSL "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin syft \
    && chmod +x /usr/bin/syft \
    # --- grype — skaner podatności na bazie SBOM (tarball) ---
    && curl -fsSL "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin grype \
    && chmod +x /usr/bin/grype \
    # --- terraform-docs — dokumentacja modułów Terraform (tarball) ---
    && curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VERSION}/terraform-docs-v${TFDOCS_VERSION}-linux-${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin terraform-docs \
    && chmod +x /usr/bin/terraform-docs \
    # --- tflint — linter Terraform (zip → unzip do /tmp) ---
    && curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip" \
       -o /tmp/tflint.zip \
    && unzip -q /tmp/tflint.zip tflint -d /usr/bin \
    && chmod +x /usr/bin/tflint \
    && rm /tmp/tflint.zip \
    # --- terragrunt — DRY wrapper dla Terraform (binarka) ---
    && curl -fsSL "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH}" \
       -o /usr/bin/terragrunt \
    && chmod +x /usr/bin/terragrunt \
    # --- dive — analiza warstw obrazu Docker (tarball) ---
    && curl -fsSL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/bin dive \
    && chmod +x /usr/bin/dive \
    # --- ctop — top dla kontenerów Docker (binarka) ---
    && curl -fsSL "https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-${ARCH}" \
       -o /usr/bin/ctop \
    && chmod +x /usr/bin/ctop \
    # --- lazydocker — TUI dla Dockera (tarball) ---
    && curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" \
       -o /tmp/lazydocker_amd64.tar.gz \
    && curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_arm64.tar.gz" \
       -o /tmp/lazydocker_arm64.tar.gz \
    && tar -xzf "/tmp/lazydocker_${ARCH}.tar.gz" -C /usr/bin lazydocker \
    && chmod +x /usr/bin/lazydocker \
    && rm /tmp/lazydocker_amd64.tar.gz /tmp/lazydocker_arm64.tar.gz \
    && echo "F2.17 binarki: kubeseal helmfile k3d argocd flux cosign trivy syft grype terraform-docs tflint terragrunt dive ctop lazydocker — OK"

# ---------------------------------------------------------------------------
# LINT — obowiązkowy krok dla obrazów bootc
# Weryfikuje poprawność obrazu jako bootc-compatible OS container.
# ---------------------------------------------------------------------------
RUN bootc container lint
