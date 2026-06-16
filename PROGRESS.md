# PROGRESS — BoobsOS

Stan pracy. Aktualizuj przy każdej istotnej zmianie (patrz CLAUDE.md → „Śledzenie zmian").

## Zrobione
- **Branding (F0)** — logo przeniesione z `cycrus-ksef` do `branding/logo/`, paleta i zasady w `branding/BRANDING.md`.
- **CLAUDE.md** — dopasowany do BoobsOS (kontekst projektu + branding).
- **Decyzja: baza = Fedora**, model image-based (bootc/OCI). Szczegóły w `ARCHITECTURE.md`.
- **F1** — scaffolding szkieletu repo + minimalny `Containerfile` (FROM UBlue base-main, os-release = BoobsOS, COPY files/).
- **F2** — warstwa pakietów DevOps + włączenie Flathub:
  - Repo overlay: `files/etc/yum.repos.d/` (hashicorp, docker-ce, kubernetes v1.31, azure-cli, google-cloud-cli).
  - COPR: atim/lazygit, jdx/mise, opentofu/opentofu.
  - Zainstalowane kategorie: Docker CE, kubectl/helm/k9s/kubectx/kustomize, terraform/opentofu/ansible, narzędzia sieciowe, zsh/git/gh/glab, CLI UX (bat, eza, fzf, ripgrep, starship, lazygit, just, fastfetch, neovim, …), sekrety (vault, age, sops), build (golang, @development-tools, mise), chmura (azure-cli, google-cloud-cli, awscli2 przez bundle).
  - Binarki z GitHub: stern v1.30.0, kind v0.24.0, sops v3.9.1, AWS CLI v2.
  - Systemctl enable: docker.socket, podman.socket.
  - Flathub: `flatpak remote-add --system` (NIE instalujemy flatpaków w obrazie).

## W toku
- **Pierwszy build lokalny (docker) — hardening F2.** Build zweryfikowany realnie na Fedorze 44 (baza UBlue base-main). Ustalenia i naprawy:
  - Większość narzędzi JEST w Fedora 44 (k9s, helm, opentofu, kustomize, eza, fd-find, bat, git-delta, zoxide, fastfetch, yq=mikefarah, just, glab, gh, age…). Zbędne COPR-y usunięte — został tylko `atim/lazygit`.
  - `mise` → własne repo `files/etc/yum.repos.d/mise.repo` (mise.jdx.dev), nie COPR.
  - Konflikt **docker-ce ↔ podman-docker/docker-cli**: dodany globalny `excludepkgs` w `files/etc/dnf/dnf.conf`. Pakiet rpm `kind` wymaga `(docker-cli OR podman-docker)` → kind instalowany jako **binarka** (nie rpm).
  - **Gotcha bootc:** `/usr/local` i `/opt` to symlinki do `/var` (poza obrazem). Wszystkie binarki (stern, kind, kubectx, kubens, sops, age-plugin-yubikey, starship, AWS CLI) → `/usr/bin` / `/usr/libexec`, NIE `/usr/local/bin`.
  - `starship` i `age-plugin-yubikey` → binarki (brak w Fedora 44); `pcsc-lite` dodany dla YubiKey; `unzip` dla bundla AWS.
  - Metoda walidacji: dry-run `dnf --assumeno` + HEAD-check URL-i w kontenerze bazy zamiast wielu pełnych rebuildów.

## Decyzje (zatwierdzone)
1. Środowisko graficzne: **GNOME**.
2. Baza obrazu: **Universal Blue `base-main`** (`ghcr.io/ublue-os/base-main`).
3. Hosting/CI: **GitLab** (rejestr + CI).

## Podgląd VM (qcow2 + QEMU)
- ✅ Bootowalny **qcow2** wygenerowany przez bib (`bib-output/qcow2/disk.qcow2`), konto demo `boobs`/`boobs`, autologin GNOME. Bootuje UEFI → GRUB „BoobsOS".
- Skrypt `run-vm.sh` (VNC + SSH na Tailscale 100.102.29.104). Szczegóły i pułapki: `VM-PREVIEW.md`.
- **Ograniczenie:** sandbox agenta blokuje hostowe qemu (display/VNC → sygnał 16) — VM uruchamia się ręcznie na hoście, nie z poziomu agenta.

## F3 — Branding w systemie (ZROBIONE)

### Co weszło (F3)
- **Tapeta** (`files/usr/share/backgrounds/boobsos/`):
  - `boobsos.png` (3840x2160) — gradient diagonalny #2090C0→#2563EB→#402090 + logo wyśrodkowane z glow
  - `boobsos-dark.png` — ciemniejszy wariant (dark mode)
  - Generator: `branding/make-wallpaper.py` (Pillow, odtwarzalny)
- **dconf system-wide** (`files/etc/dconf/`):
  - `profile/user` — user-db:user + system-db:local/site/distro
  - `db/local.d/00-boobsos` — ciemny motyw, accent=blue, tapeta, button-layout, enabled-extensions
  - `db/gdm.d/01-boobsos` — logo GDM
- **GDM logo** (`files/usr/share/pixmaps/boobsos-gdm-logo.png`) — logo marki na ekranie logowania
- **Plymouth** (`files/usr/share/plymouth/themes/boobsos/`):
  - `boobsos.plymouth` — motyw two-step, tło #080F1A, pasek #2563EB
  - `watermark.png` — logo BoobsOS (256x256 RGBA)
  - Generator: `branding/make-plymouth-assets.py`
  - Motyw bazuje na animacji ze spinnera (nie bundluje własnych 36 klatek)
- **fastfetch** (`files/etc/fastfetch/config.jsonc`) — kolory marki #2563EB/#2090C0
- **os-release** — dodano `ANSI_COLOR="38;2;37;99;235"` i `LOGO=boobsos` (sekcja F3.4)
- **Containerfile F3** — zastąpił placeholder; 4 sekcje: F3.1 (gnome-ext), F3.2 (plymouth), F3.3 (dconf update), F3.4 (os-release)

### Rozszerzenia GNOME — zweryfikowane UUID
- `dash-to-panel@jderose9.github.com` (v73, Fedora 44 updates)
- `appindicatorsupport@rgcjonas.gmail.com` (v64, Fedora 44)

### Ograniczenia F3 (znane)
- **arc-menu** — NIE dostępne w Fedora 44 repo; do instalacji przez użytkownika (Extension Manager/Flathub)
- **Tło GDM** — pełny obraz tapety na ekranie logowania NIE jest możliwy przez dconf (GDM ignoruje background przez dconf); wymaga motywu CSS GDM3 — pominięte; ustawiono tylko logo
- **Plymouth watermark** — motyw nadpisuje watermark.png z `/usr/share/plymouth/themes/spinner/`; własne klatki animacji nie są bundlowane (używamy animacji spinnera)
- **accent-color** — GNOME 50 (Fedora 44) wspiera klucz `accent-color` w schemacie `org.gnome.desktop.interface`; zweryfikowane przez `gsettings range`

## Następne (wg roadmapy w ARCHITECTURE.md)
- **F4** — CI + publikacja obrazu do rejestru (ghcr.io lub quay.io)
- **F5** — Generowanie ISO przez bootc-image-builder, test instalacji w VM
- **F6** — Dokumentacja użytkownika

## Założenia
- System dostarczany jako obraz OCI; ISO generowane przez `bootc-image-builder`.
- Motyw domyślny: ciemny, paleta z `branding/BRANDING.md`.

## Otwarte wątki / weryfikacja po F2
Pakiety do zweryfikowania przed buildem (mogą nie istnieć pod podaną nazwą):
- `k9s` — może wymagać COPR luminoso/k9s zamiast Fedora repo
- `kubectx` — zweryfikować nazwę rpm w Fedora repo
- `kustomize` — zweryfikować nazwę rpm
- `glab` — GitLab CLI; zweryfikować dostępność w Fedora repo
- `eza` — zweryfikować nazwę w Fedora repo
- `fd-find` — może być `fd` w Fedora repo
- `git-delta` — może być `delta` w Fedora repo
- `starship` — zweryfikować dostępność w Fedora repo
- `zoxide` — zweryfikować dostępność w Fedora repo
- `fastfetch` — zweryfikować dostępność (Fedora 39+)
- `mise` — COPR jdx/mise — zweryfikować czy COPR istnieje
- `opentofu` — COPR opentofu/opentofu — zweryfikować
- `yq` — dwie implementacje (python-yq vs go-yq); upewnić się która chcemy
- `httpie` — zweryfikować dostępność w Fedora repo
- `google-cloud-cli` — baseurl el9 x86_64 hardcode; problem na aarch64
- `age` — zweryfikować dostępność w Fedora repo
