# BoobsOS — Architektura

Desktopowy Linux pod DevOps / programistów / IT, oparty na **Fedorze**.

## Model: image-based (bootc / OCI), nie klasyczny fork

**Czego NIE robimy:**
- Nie forkujemy Fedory od zera ani nie utrzymujemy własnych repozytoriów pakietów.
- Nie konfigurujemy systemu ręcznie („zainstaluj i poklikaj") — to nie jest reprodukowalne.

**Co robimy:**
- Bierzemy oficjalny obraz **`quay.io/fedora/fedora-bootc`** jako `FROM`.
- W jednym `Containerfile` deklaratywnie dokładamy: pakiety, konfigurację, branding,
  domyślne ustawienia pulpitu, włączone usługi.
- Budujemy to w CI jak każdy kontener → publikujemy obraz do rejestru (ghcr/quay).
- Z obrazu generujemy instalowalne ISO/qcow2 przez **`bootc-image-builder`**.

System = **wersjonowany obraz OCI**. Stąd: aktualizacje atomowe (`bootc upgrade`),
rollback (`bootc rollback`), brak „rozjeżdżania się" instalacji, pełna reprodukowalność.

```
quay.io/fedora/fedora-bootc:42   ← baza Fedory (upstream)
            │  FROM
            ▼
   Containerfile (NASZA warstwa)
   ├─ pakiety DevOps/dev
   ├─ branding (logo, tapeta, Plymouth, GDM, os-release)
   ├─ domyślny motyw ciemny + paleta marki
   └─ usługi, flatpak/flathub, homebrew
            │  build w CI
            ▼
   ghcr.io/<org>/boobsos:latest   ← obraz BoobsOS
            │  bootc-image-builder
            ▼
   boobsos.iso / .qcow2 / .raw    ← instalacja na sprzęt/VM
```

## Jak użytkownik dostaje system

1. **Instalacja od zera** — ISO wygenerowane z obrazu (Anaconda).
2. **Rebase z istniejącej Fedory Atomic** — `bootc switch ghcr.io/<org>/boobsos:latest`.
   Każdy użytkownik Fedora Silverblue/atomic może przejść na BoobsOS jedną komendą.

## Jak to ma wyglądać (UX systemu)

- **Środowisko graficzne:** GNOME (flagowiec Fedory, Wayland) — domyślnie ciemny motyw. *(decyzja otwarta: GNOME vs KDE — patrz niżej)*
- **Branding:** tapeta z gradientem niebiesko-fioletowym + znak, splash bootu (Plymouth),
  ekran logowania (GDM), `os-release` = BoobsOS, ASCII art (fastfetch) w barwach marki.
- **Z pudełka pod DevOps/dev:**
  - Kontenery: `podman`, `docker`, `distrobox`/`toolbx`
  - K8s/chmura: `kubectl`, `helm`, `k9s`, `terraform`/`opentofu`, `ansible`, CLI aws/gcloud/az
  - Dev: `git`, `gh`/`glab`, edytory (VSCode/neovim), `zsh` + `starship`, `fastfetch`
  - Flatpak + Flathub włączone; Homebrew dla narzędzi CLI (wzorzec Universal Blue)
- **Filozofia:** „włącz i pracuj" — środowisko gotowe bez rozgrzebywania konfiguracji.

## Stos technologiczny

| Warstwa            | Wybór                                          |
|--------------------|------------------------------------------------|
| Baza               | Universal Blue `silverblue-main` (Fedora Atomic, GNOME) |
| Definicja systemu  | `Containerfile`                                |
| Build obrazu       | Podman/Buildah w CI                            |
| Rejestr            | ghcr.io lub quay.io                            |
| Generowanie ISO    | `bootc-image-builder`                          |
| Aktualizacje       | `bootc` (atomowe, rollback)                    |
| Pakiety nadbudowa  | rpm (warstwa), Flatpak (apki GUI), Homebrew (CLI) |

## Precedens / inspiracja

**Bluefin** (Universal Blue) — Fedora-atomic desktop „for developers and cloud-native".
Dokładnie nasz przypadek użycia. Opcje startu:
- **A) Czysta Fedora bootc** — pełna niezależność, więcej pracy bazowej. *(rekomendowane dla kontroli)*
- **B) Na bazie obrazu Universal Blue** (`ghcr.io/ublue-os/...`) — szybszy start (kodeki,
  sterowniki, poprawki już rozwiązane), kosztem zależności od ich obrazu.

## Decyzje (zatwierdzone)

1. **Środowisko graficzne: GNOME.** Wayland, flagowiec Fedory, najmniej utrzymania, najłatwiej spójnie obrandować. KDE jako ewentualny spin w przyszłości.
2. **Baza obrazu: Universal Blue `silverblue-main` (GNOME).** Fedora Atomic z pełnym GNOME + GDM, rozwiązanymi kodekami/sterownikami/akmods, bez ich brandingu. `FROM ghcr.io/ublue-os/silverblue-main:latest`. UWAGA: `base-main` jest HEADLESS (bez DE) — dlatego dla desktopu używamy `silverblue-main`. KDE = `kinoite-main`. Zamiana = jedna linijka.
3. **Hosting/CI: GitLab** (rejestr + GitLab CI), spójnie z `cycrus-ksef`.

## Roadmap (fazy)

- **F0 — Branding** ✅ (logo + paleta w `branding/`)
- **F1 — Szkielet repo + minimalny `Containerfile`** (FROM fedora-bootc, os-release = BoobsOS, build lokalnie)
- **F2 — Pakiety DevOps + domyślny pulpit** (DE, motyw ciemny, narzędzia)
- **F3 — Branding w systemie** (Plymouth, GDM, tapeta, fastfetch)
- **F4 — CI + publikacja obrazu** do rejestru
- **F5 — Generowanie ISO** przez bootc-image-builder, test instalacji w VM
- **F6 — Dokumentacja użytkownika** (instalacja, rebase, aktualizacje)
