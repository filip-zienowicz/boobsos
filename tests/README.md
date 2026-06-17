# Autotesty obrazów BoobsOS

Skrypt `test-image.sh` wykonuje szybką (kontenerową, bez bootowania) walidację
zbudowanego obrazu OCI. Nie wymaga instalacji ani uruchomienia systemu —
wszystkie sprawdzenia odbywają się w krótkotrwałych kontenerach podman.

## Wymagania

- `podman` zainstalowany lokalnie
- Obraz musi być dostępny lokalnie w podman (po `podman build` lub `podman pull`)

## Uruchomienie lokalne

```bash
# Po lokalnym buildzie edycji dev:
podman build -f Containerfile -t localhost/boobsos:dev .
./tests/test-image.sh localhost/boobsos:dev

# Po lokalnym buildzie edycji game:
podman build -f editions/game/Containerfile -t localhost/boobsos:game .
./tests/test-image.sh localhost/boobsos:game

# Testowanie obrazu z rejestru (musi być spullowany):
podman pull ghcr.io/filip-zienowicz/boobsos:abc1234
./tests/test-image.sh ghcr.io/filip-zienowicz/boobsos:abc1234
```

## Co jest sprawdzane

Skrypt automatycznie wykrywa edycję z `VARIANT_ID` w `/usr/lib/os-release`.

### Wspólne (dev i game)

| Check | Co weryfikuje |
|-------|---------------|
| os-release: NAME | `NAME="BoobsOS"` w os-release |
| os-release: ID | `ID=boobsos` w os-release |
| os-release: PRETTY_NAME | zawiera "BoobsOS" |
| boobsos-edition | binarka istnieje i jest wykonywalna |
| cycrus.repo | `/etc/yum.repos.d/cycrus.repo` istnieje |
| branding: icon | `/usr/share/icons/hicolor/256x256/apps/boobsos.png` |
| branding: tło | `/usr/share/backgrounds/boobsos/boobsos.png` |
| branding: plymouth | katalog `/usr/share/plymouth/themes/boobsos` |
| dconf: welcome-dialog | klucz `welcome-dialog-last-shown-version` w 00-boobsos |
| dconf: dash-to-panel | `dash-to-panel@jderose9.github.com` w 00-boobsos |
| service: firewalld | `systemctl is-enabled firewalld.service` → enabled |
| service: bootc-timer | `systemctl is-enabled bootc-fetch-apply-updates.timer` → enabled |
| bootc | binarka `bootc` dostępna |

### Dev (VARIANT_ID=desktop)

| Check | Co weryfikuje |
|-------|---------------|
| kubectl, terraform, docker, code, helm, ansible | binarki dostępne |
| dconf: accent-color | `accent-color='blue'` |

### Game (VARIANT_ID=game)

| Check | Co weryfikuje |
|-------|---------------|
| gamemode | `rpm -q gamemode` |
| mangohud | `rpm -q mangohud` |
| steam-devices | `rpm -q steam-devices` |
| vulkaninfo | binarka dostępna |
| boobsos-gpu-autorebase | service enabled |
| dconf: accent-color | `accent-color='red'` |
| BRAK kubectl | negatywny — DevOps tools nie mogą być w game |
| BRAK terraform | negatywny |
| BRAK code (VS Code) | negatywny |

## Wyjście

Skrypt loguje `PASS`/`FAIL` dla każdego czeku i kończy:
- `exit 0` — wszystkie testy przeszły
- `exit 1` — przynajmniej jeden FAIL

## CI

Testy są automatycznie uruchamiane w CI po każdym buildzie (przed push do rejestru):
- GitHub Actions: `.github/workflows/build.yml`, `.github/workflows/build-game.yml`
- GitLab CI: `.gitlab-ci.yml` (stage `test`)
