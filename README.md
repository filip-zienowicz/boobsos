![BoobsOS](branding/logo/boobsos-logo.png)

# BoobsOS

Desktopowy Linux dla DevOps, programistów i inżynierów IT — oparty na Fedorze Atomic (bootc/OCI).
Środowisko gotowe do pracy od razu po instalacji: kontenery, Kubernetes, narzędzia chmurowe, edytory.

## Jak to działa

System dostarczany jest jako **wersjonowany obraz OCI** (nie klasyczny ISO z pakietami).
Aktualizacje są atomowe (`bootc upgrade`), rollback jedną komendą (`bootc rollback`).
Szczegóły architektury: [ARCHITECTURE.md](ARCHITECTURE.md) | Branding: [branding/BRANDING.md](branding/BRANDING.md).

---

## Budowanie lokalnie

Wymaga: `podman` zainstalowanego lokalnie (Fedora, RHEL, Ubuntu z podmanem).

```bash
./build.sh
```

Zbudowany obraz dostępny jako `boobsos:dev`:

```bash
podman run --rm -it boobsos:dev bash
```

---

## Generowanie ISO

Do generowania ISO z obrazu OCI służy `bootc-image-builder`.
Wymaga root / podman z `--privileged`.

```bash
# Najpierw wypchnij obraz do rejestru lub zbuduj lokalnie przez ./build.sh
sudo podman run \
    --rm \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v $(pwd)/output:/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    ghcr.io/osbuild/bootc-image-builder:latest \
    --type iso \
    --local \
    localhost/boobsos:dev

# Wynik: output/bootiso/install.iso
```

---

## Rebase z istniejącej Fedory Atomic

Jeśli masz zainstalowaną Fedorę Silverblue / Fedorę Atomic, możesz przejść na BoobsOS jedną komendą:

```bash
sudo bootc switch ghcr.io/<org>/boobsos:latest
```

Po restarcie system uruchomi się jako BoobsOS. Rollback: `sudo bootc rollback`.

---

## CI/CD

Pipeline GitLab (`.gitlab-ci.yml`) buduje obraz przy każdym push i publikuje go
do GitLab Container Registry przy push na gałąź `main`.

---

## Co jest z pudełka

Środowisko gotowe do pracy od razu po instalacji — bez konfiguracji po instalacji:

| Kategoria | Narzędzia |
|-----------|-----------|
| Kontenery | Docker CE, Podman, Buildah, Skopeo, Distrobox, docker-compose |
| Kubernetes | kubectl, helm, k9s, kubectx/kubens, kustomize, stern, kind |
| IaC | Terraform, OpenTofu, Ansible |
| Chmura | AWS CLI v2, azure-cli (az), google-cloud-cli (gcloud) |
| Sekrety | Vault (HashiCorp), SOPS, age (+ YubiKey plugin), GnuPG, pass |
| Git i hosting | git, git-lfs, gh (GitHub CLI), glab (GitLab CLI), lazygit |
| Shell | zsh, tmux, starship (prompt), fastfetch |
| CLI UX | neovim, fzf, ripgrep, bat, eza, fd, zoxide, jq, yq, git-delta, direnv, htop, btop, ncdu, tree |
| Build/języki | gcc/make (@development-tools), Go, Python 3, mise (node/ruby/etc.) |
| Sieć | nmap, tcpdump, mtr, wireshark-cli (tshark), httpie, wireguard-tools, iperf3, socat, mtr |
| Flatpak/GUI | Flathub włączony (VSCode, Spotify, Firefox przez `flatpak install flathub …`) |

---

## Roadmap

| Faza | Opis | Status |
|------|------|--------|
| F0 | Branding (logo, paleta) | ✅ |
| F1 | Szkielet repo + minimalny Containerfile | ✅ |
| F2 | Pakiety DevOps + Flathub | ✅ |
| F3 | Branding w systemie (Plymouth, GDM, tapeta) | ⬜ |
| F4 | CI + publikacja obrazu do rejestru | ⬜ |
| F5 | Generowanie ISO, test w VM | ⬜ |
| F6 | Dokumentacja użytkownika | ⬜ |
