# PROGRESS — BoobsOS

Stan pracy. Aktualizuj przy każdej istotnej zmianie (patrz CLAUDE.md → „Śledzenie zmian").

## Zrobione
- **Branding (F0)** — logo przeniesione z `cycrus-ksef` do `branding/logo/`, paleta i zasady w `branding/BRANDING.md`.
- **CLAUDE.md** — dopasowany do BoobsOS (kontekst projektu + branding).
- **Decyzja: baza = Fedora**, model image-based (bootc/OCI). Szczegóły w `ARCHITECTURE.md`.

## W toku
- **F1** — scaffolding szkieletu repo + minimalny `Containerfile` (delegowane do Sonneta).

## Decyzje (zatwierdzone)
1. Środowisko graficzne: **GNOME**.
2. Baza obrazu: **Universal Blue `base-main`** (`ghcr.io/ublue-os/base-main`).
3. Hosting/CI: **GitLab** (rejestr + CI).

## Następne (wg roadmapy w ARCHITECTURE.md)
- **F2** — pakiety DevOps + domyślny pulpit (motyw ciemny, narzędzia).

## Założenia
- System dostarczany jako obraz OCI; ISO generowane przez `bootc-image-builder`.
- Motyw domyślny: ciemny, paleta z `branding/BRANDING.md`.
