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

## F2.14 — Aplikacje desktop + baseline bezpieczeństwa (ZROBIONE)

### Co weszło (F2.14)

**Nowe repo:**
- `files/etc/yum.repos.d/vscode.repo` — Microsoft repo dla VS Code

**Nowe pliki overlay:**
- `files/usr/libexec/boobsos-install-flatpaks` — skrypt instalujący flatpaki przy pierwszym boocie (lista FLATPAKS na górze; domyślnie: org.onlyoffice.desktopeditors)
- `files/etc/systemd/system/boobsos-firstboot-flatpaks.service` — oneshot, After=network-online.target, ConditionPathExists=!/var/lib/boobsos/firstboot-flatpaks.done
- `files/etc/logrotate.d/boobsos` — polityka logrotate dla /var/log/boobsos/*.log (weekly, rotate 7, compress, missingok, notifempty)

**Sekcja Containerfile F2.14:**
- Import klucza GPG Microsoft + `dnf install -y code` (VS Code z vscode.repo)
- `dnf install -y openconnect NetworkManager-openconnect NetworkManager-openconnect-gnome`
- `dnf install -y torbrowser-launcher` (Fedora repo, launcher pobiera Tor Browser kryptograficznie przy 1. uruchomieniu)
- `systemctl enable boobsos-firstboot-flatpaks.service` (OnlyOffice przez flatpak przy 1. boocie)
- `systemctl enable firewalld.service auditd.service logrotate.timer`

**Walidacja dry-run (dnf --assumeno):**
- `code` (z vscode.repo): OK — wersja 1.124.2
- `openconnect` / `NetworkManager-openconnect` / `NetworkManager-openconnect-gnome`: OK — już w bazie silverblue-main (zainstalowane)
- `torbrowser-launcher`: OK — wersja 0.3.9-3.fc44 (Fedora repo)
- `firewalld` / `audit` / `logrotate`: OK — już w bazie silverblue-main, preset enabled
- `bash -n boobsos-install-flatpaks`: OK

**Uwagi architektoniczne:**
- firewalld, auditd, logrotate — JUŻ w bazie silverblue-main i JUŻ enabled; `systemctl enable` w Containerfile idempotentne (zabezpieczenie na zmianę bazy)
- WireGuard — wireguard-tools zainstalowany w F2.6; NetworkManager ma natywne wsparcie WireGuard (nie potrzeba dodatkowego pakietu)
- OnlyOffice — brak dobrego rpm dla Fedory; flatpak z Flathub przez oneshot systemd (wzorzec Universal Blue)
- strefa firewalld: FedoraWorkstation (domyślna) — SSH dozwolone, porty >1024 dozwolone; NIE zmieniane agresywnie

## F2.15 — Domyślne dotfiles (neovim + oh-my-zsh) (ZROBIONE)

### Co weszło (F2.15)

**Nowe pliki overlay (przez COPY files/ /):**
- `files/etc/skel/.config/nvim/init.lua` — pełna konfiguracja neovim (177 linii):
  lazy.nvim bootstrap, LSP (mason + mason-lspconfig 2.0 API), treesitter, telescope, nvim-tree,
  nvim-cmp z luasnip, gitsigns, autopairs, comment. Pluginy + LSP instalują się przy 1. starcie nvima.
- `files/etc/skel/.zshrc` — konfiguracja zsh (35 linii):
  oh-my-zsh, theme ys, plugins (git zsh-autosuggestions zsh-syntax-highlighting),
  aliasy ls/ll/la przez eza (fallback do ls --color), aliasy cat → bat, HISTSIZE=50000.

**Sekcja Containerfile F2.15 (PRZED `bootc container lint`):**
- `dnf install -y nodejs22 nodejs22-npm` — runtime dla Mason LSP instalatorów.
  (Fedora 44 nie ma generycznego `nodejs`/`npm`; nodejs22 = aktywne LTS).
- `git clone` oh-my-zsh do `/etc/skel/.oh-my-zsh` (depth=1, slim).
- `git clone` zsh-autosuggestions i zsh-syntax-highlighting do custom/plugins.
- `find ... -name .git -type d -prune -exec rm -rf {}` — usunięcie .git z all clones.
- `chmod -R a+rX /etc/skel` — poprawne uprawnienia skel.

**Zależności LSP/mason/treesitter — weryfikacja:**
- `gcc`/`make` — dostępne (@development-tools, F2.10 ✅)
- `python3-pip` — dostępny (F2.10 ✅)
- `ripgrep`/`fd-find` — dostępne (F2.8 ✅)
- `git` — dostępny (F2.7 ✅)
- `nodejs22`/`nodejs22-npm` — NOWE (F2.15); zweryfikowane: nodejs22-1:22.22.2-3.fc44.x86_64, nodejs22-npm-1:10.9.7-1.22.22.2.3.fc44.noarch

**Mechanizm działania dla nowych userów:**
- `useradd -m` kopiuje `/etc/skel/` → `$HOME/` (standard Linux).
- `.zshrc` odwołuje się do `$HOME/.oh-my-zsh` — po skopiowaniu z skel działa bez zmian.
- `init.lua` bootstrappuje lazy.nvim przy 1. starcie nvima; Mason auto-instaluje LSP.

## F4 — Przeglądarki, narzędzia, hostname, Desktop (ZROBIONE)

### Co weszło (F4)

**Hostname:**
- `files/etc/hostname` = `boobsos` (jeden plik overlay, jedna linia)
- Containerfile: dodana podmiana `CPE_NAME` do bloku sed (os-release) + fallback RUN jeśli pole nie istnieje

**Nautilus — Desktop w panelu bocznym:**
- `files/etc/skel/.config/user-dirs.dirs` — XDG_DESKTOP_DIR="$HOME/Desktop" + pozostałe standardowe katalogi
- `files/etc/skel/.config/user-dirs.locale` = `en_US`
- `files/etc/skel/Desktop/.keep` — pusty plik utrzymujący katalog
- Metoda: XDG user-dirs (pewna; działa przez skopiowanie skel przy useradd -m). Bookmarks GTK pominięte — XDG dir wystarczy by Nautilus pokazał Desktop w bocznym panelu.

**Przeglądarki:**
- `files/etc/yum.repos.d/google-chrome.repo` — Google Chrome (baseurl dl.google.com, gpgcheck=1)
- `files/etc/yum.repos.d/brave-browser.repo` — Brave Browser (baseurl s3.brave.com, gpgcheck=1)
- Containerfile F4.1: import kluczy GPG + `dnf install -y google-chrome-stable` + `dnf install -y brave-browser`

**Pasek zadań (favorite-apps):**
- `files/etc/dconf/db/local.d/00-boobsos` — dodano klucz `favorite-apps` w sekcji `[org/gnome/shell]`
- Lista: `['brave-browser.desktop', 'code.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Ptyxis.desktop', 'org.gnome.Settings.desktop']`
- Firefox odpięty (zainstalowany), org.gnome.Software odpięty, Chrome zainstalowany ale nie przypięty

**Narzędzia sieciowe/kryptograficzne:**
- Containerfile F4.2: `dnf install -y hping3 hashcat` (oba z głównego Fedora repo, bez RPM Fusion)

**gnome-tour rebranding:**
- POMINIĘTE (best-effort). Zasoby zidentyfikowane: welcome.svg w /org/gnome/Tour/welcome.svg. Podmiana zbyt krucha — zostaw TODO w Containerfile.

**Dry-run (dnf) — wyniki:**
- `google-chrome-stable` 149.0.7827.114-1 → OK (z google-chrome.repo)
- `brave-browser` 1.91.172-1 + brave-keyring → OK (z brave-browser.repo)
- `hping3` 0.0.20051105 → OK (repo: fedora, bez RPM Fusion)
- `hashcat` 7.1.2 → OK (repo: fedora, bez RPM Fusion)

**Zweryfikowane .desktop ID:**
- `org.gnome.Ptyxis.desktop` — terminal w silverblue-main (nie Console, nie gnome-terminal)
- `org.gnome.Nautilus.desktop` — Files / Menedżer plików
- `org.gnome.Settings.desktop` — Ustawienia
- `brave-browser.desktop` — z pakietu brave-browser (razem z com.brave.Browser.desktop)
- `code.desktop` — VS Code (z pakietu code, vscode.repo)

## Następne (wg roadmapy w ARCHITECTURE.md)
- **F5** — CI + publikacja obrazu do rejestru (ghcr.io lub quay.io)
- **F6** — Generowanie ISO przez bootc-image-builder, test instalacji w VM
- **F7** — Dokumentacja użytkownika

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
