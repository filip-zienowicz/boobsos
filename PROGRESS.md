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
_(brak — F2 ukończone; F3 następne)_

## Decyzje (zatwierdzone)
1. Środowisko graficzne: **GNOME**.
2. Baza obrazu: **Universal Blue `base-main`** (`ghcr.io/ublue-os/base-main`).
3. Hosting/CI: **GitLab** (rejestr + CI).

## Następne (wg roadmapy w ARCHITECTURE.md)
- **F3** — branding w systemie: Plymouth (splash), GDM (ekran logowania), tapeta pulpitu, fastfetch ASCII art z paletą BoobsOS.

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
