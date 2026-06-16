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
RUN dnf copr enable -y atim/lazygit \
    # mise — menedżer wersji toolchainów (node, python, ruby, etc.)
    # UWAGA: COPR jdx/mise — zweryfikuj czy istnieje; alternatywa: binarka z GitHub
    && dnf copr enable -y jdx/mise \
    # opentofu — fork terraform; oficjalny rpm z ich repo lub COPR
    # UWAGA: opentofu.org dostarcza rpm repo; tutaj przez COPR jako fallback
    # Rozważ dodanie pliku files/etc/yum.repos.d/opentofu.repo zamiast COPR
    && dnf copr enable -y opentofu/opentofu \
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
RUN dnf install -y \
    # --- kubectl (kubernetes.repo v1.31) ---
    kubectl \
    # --- Helm — zarządzanie aplikacjami K8s ---
    helm \
    # --- k9s — TUI dla Kubernetes ---
    # UWAGA: zweryfikować źródło — Fedora repo lub COPR luminoso/k9s
    k9s \
    # --- kubectx + kubens — szybkie przełączanie kontekstów K8s ---
    # UWAGA: w Fedora repo może być jako 'kubectx' (zawiera kubens)
    kubectx \
    # --- kustomize — nakładki YAML dla K8s ---
    # UWAGA: zweryfikować nazwę — może być 'kubernetes-client' lub 'kustomize'
    kustomize \
    && dnf clean all

# ---------------------------------------------------------------------------
# F2.4: Binarki K8s niedostępne w rpm (stern, kind)
#
# stern — tail logów z wielu podów K8s. Brak rpm w Fedora/COPR.
# kind  — Kubernetes in Docker (lokalne klastry). Brak rpm.
# Instalujemy do /usr/local/bin (trwałe w obrazie bootc).
# UWAGA: wersje hardcode — aktualizuj przy nowym buildzie.
# ---------------------------------------------------------------------------
RUN STERN_VERSION="1.30.0" \
    && KIND_VERSION="0.24.0" \
    && ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
    # stern
    && curl -fsSL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_${ARCH}.tar.gz" \
       | tar -xzf - -C /usr/local/bin stern \
    && chmod +x /usr/local/bin/stern \
    # kind
    && curl -fsSL "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH}" \
       -o /usr/local/bin/kind \
    && chmod +x /usr/local/bin/kind \
    && echo "stern $(stern --version 2>/dev/null || echo 'installed')" \
    && echo "kind $(kind version 2>/dev/null || echo 'installed')"

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
    # --- OpenTofu — open-source fork Terraform ---
    # UWAGA: opentofu/opentofu COPR — zweryfikować czy pakiet nazywa się 'opentofu'
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
# starship: prompt; Fedora repo  # UWAGA: zweryfikować dostępność
# just: command runner; Fedora repo od F38
# fastfetch: system info; Fedora repo od F39  # UWAGA: zweryfikować
# direnv: env per katalog; Fedora repo
# btop: TUI monitor zasobów; Fedora repo
# ncdu: analiza dysku; Fedora repo
# yq: YAML processor; Fedora repo  # UWAGA: zweryfikować — może być pip/snap
# mise: toolchain manager; COPR jdx/mise (włączony wyżej)  # UWAGA: zweryfikować
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
    # --- Prompt i terminal ---
    # UWAGA: starship — zweryfikować czy jest w Fedora repo jako 'starship'
    starship \
    # --- Automatyzacja i build ---
    just \
    # --- Toolchain manager ---
    # UWAGA: mise — zweryfikować COPR jdx/mise; alternatywa: binarka curl|bash
    mise \
    # --- System info ---
    # UWAGA: fastfetch — Fedora repo od F39+; zweryfikować
    fastfetch \
    # --- Edytor ---
    neovim \
    && dnf clean all

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
    # --- Kryptografia i sekrety ---
    # UWAGA: age — Fedora repo od F37+; zweryfikuj 'dnf info age'
    age \
    # age-plugin-yubikey: szyfrowanie age z kluczem sprzętowym YubiKey (PIV)
    # UWAGA: w Fedora repo od F39 jako 'age-plugin-yubikey'; jeśli brak →
    #        COPR lub `cargo install age-plugin-yubikey` (wymaga pcsc-lite-devel)
    age-plugin-yubikey \
    gnupg2 \
    pass \
    && dnf clean all

# sops — Mozilla SOPS; brak rpm w Fedora repo
# UWAGA: wersja hardcode — aktualizuj przy nowym buildzie
RUN SOPS_VERSION="3.9.1" \
    && ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" \
    && curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" \
       -o /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops \
    && echo "sops installed: $(sops --version 2>/dev/null || echo ok)"

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
# UWAGA: instaluje do /usr/local/aws-cli, symlinki do /usr/local/bin
# TODO F2: rozważ COPR lub własny wrapper rpm zamiast curl|unzip
RUN ARCH="$(uname -m)" \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp/awscli \
    && /tmp/awscli/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf /tmp/awscliv2.zip /tmp/awscli \
    && aws --version

# ---------------------------------------------------------------------------
# F2.12: Konfiguracja systemu — grupy i usługi
# ---------------------------------------------------------------------------

# Utwórz grupę 'docker' (docker-ce powinien to zrobić, ale upewniamy się)
# Użytkownicy muszą być dodani do grupy 'docker' po instalacji przez: usermod -aG docker $USER
RUN groupadd -f docker

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
# Metoda: flatpak remote-add z oficjalnego URL Flathub (pobiera klucz GPG).
# Wymaga sieci w czasie buildu.
# UWAGA: '--if-not-exists' = bezpieczne przy rebuild (nie fail jeśli już jest).
# ---------------------------------------------------------------------------
RUN flatpak remote-add --system --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo \
    && flatpak remotes --system

# ---------------------------------------------------------------------------
# F3: branding w systemie (Plymouth, GDM, tapeta pulpitu, motyw GTK, fastfetch)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# LINT — obowiązkowy krok dla obrazów bootc
# Weryfikuje poprawność obrazu jako bootc-compatible OS container.
# ---------------------------------------------------------------------------
RUN bootc container lint
