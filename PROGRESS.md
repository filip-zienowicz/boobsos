# PROGRESS — BoobsOS

Stan pracy. Aktualizuj przy każdej istotnej zmianie (patrz CLAUDE.md → „Śledzenie zmian").

## Zrobione
- **Edycja BoobsOS (DevOps, niebieski motyw #2563EB)** — obraz `ghcr.io/filip-zienowicz/boobsos:latest`. Pełny stack DevOps: Docker, Kubernetes, IaC, chmura, sekrety, narzędzia sieciowe, VS Code, Brave, tradycyjny pulpit GNOME.
- **Edycja Game (czerwony motyw #DC2626, bez DevOps)** — architektura zmieniona z `FROM boobsos:latest` (błąd: dziedziczyła cały DevOps) na niezależną bazę ublue. Zawiera: branding/pulpit BoobsOS (czerwony akcent), Brave Browser, gaming RPM (gamemode, mangohud, gamescope, vulkan-tools, goverlay, steam-devices), flatpaki gaming (Steam, Lutris, Heroic, ProtonUp-Qt, Discord, OBS). Bez DevOps.
- **Edycja Game — dwa warianty GPU (czerwiec 2026)** — jeden Containerfile z `ARG BASE_IMAGE` → dwa obrazy przez matrix CI:
  - `boobsos-game:latest` (baza `silverblue-main`, mesa: AMD/Intel/nouveau)
  - `boobsos-game-nvidia:latest` (baza `silverblue-nvidia`, akmod-nvidia preinstalowane)
- **boobsos-edition** — narzędzie do przełączania edycji: `status` / `list` / `switch dev` / `switch game`. Wykonuje `bootc switch` + restart, `/home` współdzielone między edycjami.
- **Auto-rebase GPU (boobsos-gpu-autorebase)** — usługa first-boot wykrywa kartę NVIDIA w wariancie mesa i automatycznie przełącza na `boobsos-game-nvidia:latest`.
- **CI GitHub Actions + ghcr.io** — `build.yml` (boobsos:latest, schedule 05:00 UTC), `build-game.yml` (boobsos-game + boobsos-game-nvidia, matrix, schedule 06:00 UTC). Obrazy publiczne na `ghcr.io`.
- **GitHub Pages** — strona projektu: https://filip-zienowicz.github.io/boobsos/. HTML + CSS zaktualizowane o edycje dev/game, motyw kolorów kart, narzędzie boobsos-edition.
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

## Edycja BoobsOS-Game (ZROBIONE)

### Co zawiera

Edycja gamingowa budowana z **niezależnej bazy ublue** (`silverblue-main` / `silverblue-nvidia`),
NIE `FROM boobsos:latest` (poprzednia architektura dziedziczyła cały stack DevOps — błąd, naprawione).

**Nowe pliki:**
- `editions/game/Containerfile` — `ARG BASE_IMAGE` (mesa/nvidia) + rebranding + rpm gaming + COPY flatpak skryptu + GPU autorebase
- `editions/game/files/usr/libexec/boobsos-install-flatpaks` — nadpisuje bazowy skrypt; lista gaming-only (bez OnlyOffice): Steam + Lutris + Heroic + ProtonUp-Qt + Discord + OBS
- `editions/game/files/etc/fastfetch/config.jsonc` — czerwona paleta fastfetch (nadpisuje niebieską z bazy)
- `editions/game/files/etc/skel/.config/MangoHud/MangoHud.conf` — domyślny overlay (fps/temp/ram, akcent #DC2626)
- `editions/game/files/etc/gamemode.ini` — domyślne ustawienia GameMode (renice, governor performance)
- `editions/game/files/etc/hostname` — `boobsos-game` (odróżnia od dev `boobsos`)
- `editions/game/README.md` — dokumentacja edycji (co zawiera, jak zainstalować, architektura)
- `.github/workflows/build-game.yml` — CI budujący edycję gamingową (push editions/game/**, schedule 06:00 UTC, workflow_dispatch)

**Pakiety RPM gamingowe (dry-run zweryfikowany w boobsos:latest):**

| Pakiet | Wersja | Status |
|--------|--------|--------|
| gamemode | 1.8.2-4.fc44 | OK |
| mangohud | 0.8.3~rc1-2.fc44 | OK |
| gamescope | 3.16.23-1.fc44 | OK |
| vulkan-tools | 1.4.341.0-1.fc44 | OK |
| goverlay | 1.7.5-1.fc44 | OK |
| steam-devices | 1.0.0.101^... | OK |
| wine | 11.0-3.fc44 | POMINIĘTE — 2 GB extra (114 pkg); Lutris zarządza Wine-GE przez ProtonUp-Qt |

**Flatpaki (first-boot, lista gaming-only — nadpisuje listę bazową, bez OnlyOffice):**
- `com.valvesoftware.Steam`
- `net.lutris.Lutris`
- `com.heroicgameslauncher.hgl`
- `net.davidotek.pupgui2`
- `com.discordapp.Discord`
- `com.obsproject.Studio`

**Rebranding:** `PRETTY_NAME="BoobsOS Game"`, `VARIANT="Game"`, `VARIANT_ID=game`. `NAME=BoobsOS` i `ID=boobsos` bez zmian.

**CI (build-game.yml):**
- Trigger: push na `editions/game/**`, schedule `0 6 * * *` (06:00 UTC, godzinę po bazie), workflow_dispatch
- Login do ghcr.io PRZED pull bazowego obrazu (GITHUB_TOKEN)
- Buduje → `ghcr.io/filip-zienowicz/boobsos-game:latest` + SHA tag
- Zwalnia miejsce na dysku (ten sam wzorzec co build.yml)

**Walidacja:**
- `bash -n` skryptu flatpak: OK
- YAML build-game.yml: poprawny (python yaml.safe_load)
- dry-run rpm: wszystkie 6 pakietów dostępne w Fedora 44 repo

**Instalacja przez użytkownika:**
```bash
sudo bootc switch ghcr.io/filip-zienowicz/boobsos-game:latest
```

## F6 — ISO + test instalacji (ZROBIONE / zweryfikowane)

Instalacyjne ISO (Anaconda przez `bootc-image-builder`, `--type anaconda-iso`)
zbudowane i **przetestowane end-to-end** na Proxmox `root@ms01` (VM 105, OVMF/UEFI):

- ISO bootuje → instalator z brandingiem **"BOOBSOS 44 INSTALLATION"** (tytuł, nazwa
  produktu z `PRETTY_NAME`).
- Auto-instalacja (kickstart bib: `ostreecontainer` z obrazu w ISO + autopart ext4)
  wdraża system → 3 partycje: ESP 600M, /boot 2G, root ~57G.
- Bootloader spójny: ESP `/EFI/fedora/{shim,grub,grub.cfg}` + fallback
  `/EFI/BOOT/BOOTX64.EFI`; `BOOT_UUID` w bootuuid.cfg == UUID partycji /boot; BLS
  `ostree-1.conf` obecny.
- **Boot z dysku → GDM z brandingiem BoobsOS** (logo łabędzia w heksagonie, ciemny
  motyw, user `boobs`). Wpis GRUB: `BoobsOS (ostree:0)`.

### Pułapki rozwiązane podczas testu
- **`bootc switch --mutate-in-place` w %post** (kickstart bib, origin → rejestr) NIE
  pobiera obrazu — tylko przepisuje metadane origin. 401 z prywatnego rejestru nie
  przerywa instalacji.
- **PVE nie honoruje `reboot --eject`** z kickstartu → CD bootuje ponownie → pętla
  reinstalacji; `clearpart` drugiej instalacji psuje bootloader pierwszej (niespójne
  UUID ESP vs /boot → GRUB `no such device`). **Fix testowy:** boot order
  `scsi0;ide2` (pusty dysk → fallback na CD → po instalacji dysk bootowalny wygrywa,
  brak pętli). Na realnym sprzęcie eject/wyjęcie nośnika działa normalnie.
- **VARIANT_ID** finalnie `desktop` (force-replace w Containerfile, commit `7797ba9`);
  obraz na ghcr zweryfikowany. Finalna ISO budowana z `ghcr.io/.../boobsos:latest`.
- **def `boobsos-44.yaml`** trackowany w repo i montowany w build-iso.sh oraz CI
  (bez tego bib nie znajdował def dla `ID=boobsos`).

## F7 — Polish: sidebar logo, gaming, origin, cleanup (ZROBIONE)

Runda dopracowania (4 obszary, praca na subagentach, orchestracja Opus):

1. **Branding instalatora — sidebar logo** — PRÓBA COPY NIEUDANA (zweryfikowane empirycznie).
   Wgrałem pixmapy przez `COPY ... /usr/share/anaconda/pixmaps/` do obrazu OCI i przetestowałem
   pełny pipeline: push → CI build dev → `podman pull` → `build-iso.sh` → **lokalny boot ISO w QEMU**
   (fz-vm, OVMF, screendump przez monitor). Wynik: tytuł **„BOOBSOS 44 INSTALLATION" działa** (z
   `PRETTY_NAME`), ale **panel boczny WCIĄŻ pokazuje logo Fedory**. Pixmapy SĄ w obrazie OCI, ale
   bib buduje OSOBNY installer-tree z listy pakietów (`iso/defs/boobsos-44.yaml`), gdzie `fedora-logos`
   (zależność `anaconda`) dostarcza `sidebar-logo.png` — i ono wygrywa. COPY cofnięty (no-op dla
   instalatora). **Właściwy fix** = paczka `boobsos-logos` z `Provides: system-logos` +
   `Obsoletes/Conflicts: fedora-logos`, opublikowana w repo dostępnym dla bib (repo.cycx.io) i dodana
   do `boobsos-44.yaml`. Ryzyko: minimalna paczka łamie installer (fedora-logos dostarcza też grub/
   bootloader art) — bezpieczna wersja to pełny fork artworku fedora-logos. DECYZJA do podjęcia.
2. **Gaming edition** — domknięte luki (additywne overlay): czerwony fastfetch
   (`editions/game/files/etc/fastfetch/config.jsonc`), domyślny MangoHud (skel),
   `gamemode.ini`, hostname `boobsos-game`. (czerwony motyw, gry, GPU autorebase już były OK)
3. **Origin auto-update — DECYZJA**: produkcyjny origin = **`ghcr.io`** (publiczny, działa
   out-of-box, BEZ sekretu w obrazie). GitLab CI buduje jako mirror. Migracja originu na
   `gitlab.cycr.us:5050` to udokumentowany przyszły krok, ZABLOKOWANY na: (a) upublicznieniu
   rejestru GitLab, albo (b) scoped read-only deploy-token dostarczonym przez ZABEZPIECZONE ISO.
   Reguła bezpieczeństwa: NIGDY nie wlepiać pull-secretu do publicznego obrazu. Docs ujednolicone
   (README, WEBSITE-BRIEF, docs/UPDATES.md).
4. **Cleanup + hardening**: `.gitignore` (`.claude/`, `insecure-reg.conf` + untrack),
   hardening skryptów (rebuild-qcow2.sh ścieżka, build-iso.sh komentarz, test-image.sh komentarz),
   usunięte stare artefakty: `boobsos-dev.iso` (7.8G, ms01), `bib-output/qcow2/disk.qcow2` (11G, fz-vm) + logi.

## Następne / W toku
- **Weryfikacja sidebar logo** — przebudowa obrazu dev (CI lub fz-vm) → nowe ISO → boot instalatora
  → screenshot panelu bocznego (potwierdzić łabędzia zamiast Fedory).
- **repo.cycx.io** — własny rejestr produkcyjny (w toku); docelowo obrazy migrują z ghcr.io.
- **F-docs** — rozbudowa docs/index.html, FAQ Gaming, strona edycji Game.

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

## Auto-aktualizacje (nasze zasoby) — ZROBIONE

### Model docelowy

- **Obrazy OCI** hostowane w self-hosted GitLab: `gitlab.cycr.us:5050/fzienowicz/boobsos` (DevOps), `/game` (Game), `/game-nvidia` (Game+NVIDIA). Origin ustawiany przy instalacji z ISO lub przez `bootc switch`.
- **Auto-update:** `bootc-fetch-apply-updates.timer` włączony w obrazach — cyklicznie pobiera nowy digest z naszego rejestru i stosuje atomowo przy restarcie. Bez żadnej akcji użytkownika.
- **Pakiety RPM:** `repo.cycx.io/fedora/$releasever/$basearch/` — wpięte przez `cycrus.repo` w obrazie.
- **CI:** każdy push do `main` na gitlab.cycr.us uruchamia pipeline → push do gitlab.cycr.us:5050. Scheduled: 05:00 UTC (DevOps) / 05:30 UTC (Game).

### CA wpięte do obrazu

- Plik: `files/etc/pki/ca-trust/source/anchors/cycr-us-ca.crt`
- Łańcuch (publiczny, Sectigo): `*.cycr.us` → SSL2BUY EMEA RSA DV CA → Sectigo Public Server Authentication Root R46
- Anchor zawiera **dwa certyfikaty CA** (pośredni + root), oba `CA:TRUE` — bez liścia serwera.
  - Pośredni: `C=AE, O=SSL2BUY EMEA LLC, CN=SSL2BUY EMEA RSA Domain Validation Secure Server CA` (ważny 2024–2034)
  - Root: `C=GB, O=Sectigo Limited, CN=Sectigo Public Server Authentication Root R46` (ważny 2021–2046, self-signed)
- Root R46 dołączony jawnie — jest stosunkowo nowy (2021) i może nie być w domyślnym bundlu ca-certificates Fedory/UBlue.
- `update-ca-trust` wywołuje orkiestrator w Containerfile — tu tylko dostarczamy anchor.
- Weryfikacja: `openssl crl2pkcs7 -nocrl -certfile <plik> | openssl pkcs7 -print_certs -noout` — oba CA potwierdzone.

### Dokumentacja

- `docs/UPDATES.md` — pełny opis modelu aktualizacji (PL): skąd obrazy, timer, rollback, komendy użytkownika, CA, RPM, CI. Tabela składnik→źródło.

### Uwagi / wątpliwości

- gitlab.cycr.us używa **publicznego CA** (Sectigo/SSL2BUY), NIE prywatnego root CA. Informacja o „prywatnym CA" w briefie może dotyczyć self-signed lub wewnętrznego CA dla innych usług — dla registry TLS chain jest w pełni publiczny.
- `/usr/local/share/ca-certificates/cycr.us.crt` na hoście fz-vm to cert LIŚCIA (CA:FALSE, `*.cycr.us`) — nie powinien być w anchors; nie kopiujemy go do obrazu.
- Jeśli Fedora 44 base image już zawiera Sectigo R46 root w swoim bundlu ca-certificates, anchor jest nadmiarowy (ale bezpieczny — idempotentny).
