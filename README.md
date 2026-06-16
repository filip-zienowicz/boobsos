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

## Roadmap

| Faza | Opis | Status |
|------|------|--------|
| F0 | Branding (logo, paleta) | ✅ |
| F1 | Szkielet repo + minimalny Containerfile | ✅ |
| F2 | Pakiety DevOps + domyślny pulpit | ⬜ |
| F3 | Branding w systemie (Plymouth, GDM, tapeta) | ⬜ |
| F4 | CI + publikacja obrazu do rejestru | ⬜ |
| F5 | Generowanie ISO, test w VM | ⬜ |
| F6 | Dokumentacja użytkownika | ⬜ |
