# BoobsOS — Budowanie ISO (Anaconda)

ISO instalacyjne BoobsOS generowane jest przy pomocy
[bootc-image-builder](https://github.com/osbuild/bootc-image-builder) (bib)
z opublikowanego obrazu OCI.

## Wymagania

- Fedora 44, podman zainstalowany
- `sudo` / uprawnienia do `--privileged`
- Obraz OCI BoobsOS dostępny lokalnie lub w rejestrze

## Jak zbudować ISO

### Z lokalnego obrazu (tryb dev)

```bash
# Najpierw zbuduj obraz lokalnie (jeśli jeszcze nie ma)
sudo podman build -t localhost/boobsos:dev .

# Zbuduj ISO
bash iso/build-iso.sh localhost/boobsos:dev
```

### Z rejestru

```bash
bash iso/build-iso.sh registry.gitlab.cycr.us/fzienowicz/boobsos:latest
```

### Domyślne wywołanie (localhost/boobsos:dev)

```bash
bash iso/build-iso.sh
```

## Wynik

Plik ISO pojawi się w:

```
iso-output/bootiso/install.iso
```

> **Uwaga:** Katalog `iso-output/` powinien być dodany do `.gitignore`
> — bib generuje tam duże pliki pośrednie i wynikowy obraz ISO.

## Konfiguracja

`iso/config.toml` — konfiguracja bib:
- Konto instalacyjne: `boobs` / hasło: `boobs` (grupa `wheel`)
- rootfs: ext4 (przekazywane jako `--rootfs ext4` do bib)
- Kickstart: domyślny (instalator graficzny Anaconda)

## Branding instalatora

- **Nazwa produktu** pochodzi z `os-release` (`PRETTY_NAME="BoobsOS"`) — ustawione w `Containerfile`
- **Logo i grafiki Anacondy** dostarcza paczka `boobsos-anaconda-branding` (RPM),
  zainstalowana w obrazie OCI:
  - `/usr/share/anaconda/pixmaps/sidebar-logo.png` (150x150, logo na pasku bocznym)
  - `/usr/share/anaconda/pixmaps/boobsos-logo.png` (200x200, pełne logo)
  - `/usr/share/anaconda/pixmaps/sidebar-bg.png` (230x600, tło paska bocznego)
  - `/usr/share/anaconda/pixmaps/topbar-bg.png` (1920x64, tło górnego paska)

## Budowanie paczki brandingu

```bash
# Regeneracja pixmap (wymaga Pillow)
python3 packages/boobsos-anaconda-branding/make-anaconda-art.py

# Budowanie RPM
./packages/build-rpm.sh boobsos-anaconda-branding
```

Wynik: `packages/out/boobsos-anaconda-branding-1.0.0-1.noarch.rpm`
