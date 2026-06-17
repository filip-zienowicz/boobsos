# BoobsOS Game — edycja gamingowa

Czysto gamingowa edycja BoobsOS — **bez stacku DevOps**.
Bazuje bezpośrednio na `ghcr.io/ublue-os/silverblue-nvidia:latest`
(Universal Blue Silverblue + Fedora Atomic + GNOME + preinstalowane sterowniki NVIDIA).

## Czego NIE ma (w odróżnieniu od BoobsOS base)

Edycja Game **nie zawiera** żadnego z poniższych:
VS Code, Docker, Kubernetes (kubectl/helm/k9s/kustomize/kind/stern), Terraform / OpenTofu,
Ansible, AWS/Azure/gcloud CLI, HashiCorp Vault, SOPS, age, Tor Browser, openconnect VPN,
glab, lazygit, mise, neovim, zsh/oh-my-zsh, hping3, hashcat, wireshark…

## Co zawiera

| Kategoria | Zawartość |
|-----------|-----------|
| Baza | Fedora Atomic + GNOME (silverblue-nvidia) |
| Sterowniki GPU | NVIDIA (akmod-nvidia z bazy ublue) + mesa AMD/Intel |
| Branding | BoobsOS — pulpit, tapeta, Plymouth, logo (jak BoobsOS base) |
| Przeglądarka | Brave Browser (RPM) |
| Gaming RPM | gamemode, mangohud, gamescope, vulkan-tools, goverlay, steam-devices |
| Platformy (flatpak, 1. boot) | Steam, Lutris, Heroic Games Launcher |
| Narzędzia Proton (flatpak, 1. boot) | ProtonUp-Qt (manager Proton-GE / Wine-GE) |
| Komunikacja / streaming (flatpak, 1. boot) | Discord, OBS Studio |
| Identyfikacja systemu | PRETTY_NAME="BoobsOS Game", VARIANT=Game, VARIANT_ID=game |
| Pasek zadań | Ustawienia, Pliki, Terminal, Brave, Steam, Lutris, Heroic |

**Sterowniki NVIDIA** są preinstalowane w bazie ublue — nie trzeba ich konfigurować.
Edycja działa też na kartach AMD i Intel (mesa z bazy silverblue).

## Jak zainstalować

### Rebase z istniejącej Fedory Atomic / Silverblue

```bash
sudo bootc switch ghcr.io/filip-zienowicz/boobsos-game:latest
```

Uruchom ponownie. Przy pierwszym boocie usługa `boobsos-firstboot-flatpaks`
automatycznie zainstaluje Steam, Lutris, Heroic, ProtonUp-Qt, Discord i OBS.

### Rebase z istniejącego BoobsOS (base)

```bash
sudo bootc switch ghcr.io/filip-zienowicz/boobsos-game:latest
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
# z katalogu głównego repo
podman build --format docker \
  -f editions/game/Containerfile \
  -t boobsos-game:dev \
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
ghcr.io/ublue-os/silverblue-nvidia:latest   (baza ublue: GNOME + sterowniki NVIDIA)
    └── ghcr.io/filip-zienowicz/boobsos-game:latest  (CI: build-game.yml, 06:00 UTC)
```

Edycja Game jest **niezależna** od BoobsOS base — nie dziedziczy stacku DevOps.
Aktualizacje Fedory i sterowników NVIDIA propagują się automatycznie przez codzienne CI
(gdy ublue aktualizuje silverblue-nvidia, nasz build-game pobiera nową bazę).

## Dlaczego nie dziedziczymy z BoobsOS base?

Poprzednia architektura (`FROM ghcr.io/filip-zienowicz/boobsos:latest`) była błędem —
edycja Game dziedziczyła cały stack DevOps (Docker, K8s, Terraform, VS Code, Vault…),
który graczowi nie jest potrzebny i niepotrzebnie zwiększał rozmiar obrazu.

Nowa architektura: oddzielna baza nvidia → tylko gaming.
