# BoobsOS Game — edycja gamingowa

Czysto gamingowa edycja BoobsOS — **bez stacku DevOps**.
Jeden Containerfile buduje **dwa warianty GPU** (wzorzec Bazzite/ublue):
gaming RPM i flatpaki są wspólne; sterowniki GPU pochodzą z bazy.

## Dwa warianty GPU

| Wariant | Obraz | Baza ublue | GPU |
|---------|-------|-----------|-----|
| **mesa** (domyślny) | `ghcr.io/filip-zienowicz/boobsos-game:latest` | `silverblue-main` | AMD Radeon, Intel Arc/Iris Xe, nouveau (otwarte sterowniki z jądra + mesa) |
| **nvidia** | `ghcr.io/filip-zienowicz/boobsos-game-nvidia:latest` | `silverblue-nvidia` | NVIDIA (akmod-nvidia / kmod-nvidia preinstalowane przez ublue) |

### Którą wersję wybrać?

- **Karta AMD lub Intel** → wariant `boobsos-game` (mesa). Sterowniki amdgpu/i915/xe
  są w otwartym jądrze Fedory — nie trzeba żadnego dodatkowego pakietu.
- **Karta NVIDIA** → wariant `boobsos-game-nvidia`. ublue preinstaluje w bazie
  `akmod-nvidia` i `kmod-nvidia`; działa out-of-the-box po rebootcie.
- **Tylko CPU / integra Intel** → wariant mesa (ten sam obraz co AMD/Intel).

Wariant nvidia jest nadzbiorem: zawiera te same pakiety gaming co mesa plus sterowniki NVIDIA.

## Czego NIE ma (w odróżnieniu od BoobsOS base)

Edycja Game **nie zawiera** żadnego z poniższych:
VS Code, Docker, Kubernetes (kubectl/helm/k9s/kustomize/kind/stern), Terraform / OpenTofu,
Ansible, AWS/Azure/gcloud CLI, HashiCorp Vault, SOPS, age, Tor Browser, openconnect VPN,
glab, lazygit, mise, neovim, zsh/oh-my-zsh, hping3, hashcat, wireshark…

## Co zawiera (oba warianty)

| Kategoria | Zawartość |
|-----------|-----------|
| Baza | Fedora Atomic + GNOME (silverblue-main lub silverblue-nvidia) |
| Sterowniki GPU | mesa AMD/Intel/nouveau (wariant mesa) **lub** akmod-nvidia + mesa (wariant nvidia) |
| Branding | BoobsOS — pulpit, tapeta, Plymouth, logo (jak BoobsOS base) |
| Przeglądarka | Brave Browser (RPM) |
| Gaming RPM | gamemode, mangohud, gamescope, vulkan-tools, goverlay, steam-devices |
| Platformy (flatpak, 1. boot) | Steam, Lutris, Heroic Games Launcher |
| Narzędzia Proton (flatpak, 1. boot) | ProtonUp-Qt (manager Proton-GE / Wine-GE) |
| Komunikacja / streaming (flatpak, 1. boot) | Discord, OBS Studio |
| Identyfikacja systemu | PRETTY_NAME="BoobsOS Game", VARIANT=Game, VARIANT_ID=game |
| Pasek zadań | Ustawienia, Pliki, Terminal, Brave, Steam, Lutris, Heroic |

## Jak zainstalować

### Rebase z istniejącej Fedory Atomic / Silverblue — wariant mesa (AMD/Intel)

```bash
sudo bootc switch ghcr.io/filip-zienowicz/boobsos-game:latest
```

### Rebase — wariant nvidia (NVIDIA)

```bash
sudo bootc switch ghcr.io/filip-zienowicz/boobsos-game-nvidia:latest
```

Uruchom ponownie. Przy pierwszym boocie usługa `boobsos-firstboot-flatpaks`
automatycznie zainstaluje Steam, Lutris, Heroic, ProtonUp-Qt, Discord i OBS.

### Rebase z istniejącego BoobsOS (base)

```bash
# AMD/Intel:
sudo bootc switch ghcr.io/filip-zienowicz/boobsos-game:latest
# NVIDIA:
sudo bootc switch ghcr.io/filip-zienowicz/boobsos-game-nvidia:latest
```

**Uwaga:** po przełączeniu na edycję Game znikają pakiety DevOps (Docker, kubectl, itp.) —
to oddzielny obraz, nie nakładka.

### Rollback

```bash
sudo bootc rollback
```

## Jak budować lokalnie

Wymaga `podman`. Build uruchamiamy z **katalogu głównego repo** (nie z editions/game/),
bo Containerfile odwołuje się do `files/` i `editions/game/files/`:

```bash
# Wariant mesa (AMD/Intel) — domyślny ARG
podman build --format docker \
  -f editions/game/Containerfile \
  -t boobsos-game:dev \
  .

# Wariant nvidia — nadpisz ARG
podman build --format docker \
  -f editions/game/Containerfile \
  --build-arg BASE_IMAGE=ghcr.io/ublue-os/silverblue-nvidia \
  -t boobsos-game-nvidia:dev \
  .
```

Testowanie:

```bash
podman run --rm -it boobsos-game:dev bash
# sprawdź: cat /usr/lib/os-release | grep -E '^(PRETTY_NAME|VARIANT)'
# sprawdź: rpm -q gamemode mangohud gamescope brave-browser
```

## Architektura

```
ghcr.io/ublue-os/silverblue-main:latest    (baza mesa: GNOME + otwarte sterowniki GPU)
    └── ghcr.io/filip-zienowicz/boobsos-game:latest          (CI: build-game.yml)

ghcr.io/ublue-os/silverblue-nvidia:latest  (baza nvidia: GNOME + akmod-nvidia)
    └── ghcr.io/filip-zienowicz/boobsos-game-nvidia:latest   (CI: build-game.yml)
```

Jeden Containerfile (`editions/game/Containerfile`) z `ARG BASE_IMAGE` — budowany dwukrotnie
przez matrix CI (`strategy.matrix`). Gaming RPM i flatpaki identyczne w obu wariantach.

Edycja Game jest **niezależna** od BoobsOS base — nie dziedziczy stacku DevOps.
Aktualizacje Fedory i sterowników propagują się automatycznie przez codzienne CI
(gdy ublue aktualizuje bazy, nasz build-game pobiera nową bazę).

## Dlaczego dwa obrazy zamiast jednego?

Sterowniki NVIDIA wymagają osobnego obrazu bazowego (`silverblue-nvidia`) z akmod-nvidia —
nie można ich dodać do obrazu mesa za pomocą zwykłego `dnf install` (wymagają dopasowania
do konkretnej wersji jądra; ublue pakuje je w czasie budowy bazy). Wzorzec stosowany przez
Bazzite i inne projekty ublue: jeden Containerfile, dwie bazy, dwa obrazy w rejestrze.
AMD/Intel/CPU używają otwartych sterowników z jądra — nie potrzebują oddzielnych pakietów.
