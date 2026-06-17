# Aktualizacje BoobsOS — model i procedury

## Skąd pochodzą aktualizacje

BoobsOS jest oparty na modelu **image-based** (bootc/OCI). Wszystkie składniki aktualizowane są z **własnych zasobów Cycrus** — nie z ghcr.io ani publicznych repozytoriów Fedory.

| Składnik | Źródło | Uwagi |
|----------|--------|-------|
| Obrazy OCI (system) | `registry.gitlab.cycr.us/fzienowicz/boobsos` | Rejestr self-hosted GitLab |
| Obraz edycji Game | `registry.gitlab.cycr.us/fzienowicz/boobsos/game` | |
| Obraz edycji Game (NVIDIA) | `registry.gitlab.cycr.us/fzienowicz/boobsos/game-nvidia` | |
| Pakiety RPM | `repo.cycx.io/fedora/$releasever/$basearch/` | Skonfigurowane przez `cycrus.repo` |

---

## Model aktualizacji obrazu OCI

### Auto-aktualizacje (timer)

W każdym obrazie BoobsOS włączony jest `bootc-fetch-apply-updates.timer` (usługa systemd). Timer działa w tle:

1. Regularnie sprawdza, czy w rejestrze (`registry.gitlab.cycr.us`) dostępny jest nowy obraz.
2. Jeśli tak — pobiera go i przygotowuje do zastosowania.
3. Przy następnym **restarcie systemu** nowy obraz zostaje aktywowany atomowo.

Nie jest wymagana żadna akcja ze strony użytkownika. Aktualizacje są atomowe — w razie problemu system można cofnąć (patrz: rollback).

### Origin obrazu

Przy instalacji BoobsOS (z ISO lub przez `bootc switch`) origin systemu ustawiany jest na odpowiedni obraz w naszym rejestrze:

```
registry.gitlab.cycr.us/fzienowicz/boobsos:latest          # edycja DevOps
registry.gitlab.cycr.us/fzienowicz/boobsos/game:latest     # edycja Game
registry.gitlab.cycr.us/fzienowicz/boobsos/game-nvidia:latest  # edycja Game + NVIDIA
```

Timer i `bootc upgrade` zawsze operują względem tego originu — nie ma możliwości przypadkowego pobrania obrazu z zewnętrznego rejestru.

---

## Komendy dla użytkownika

### Ręczna aktualizacja

```bash
sudo bootc upgrade
```

Pobiera najnowszy obraz z rejestru i aplikuje przy kolejnym restarcie. Aby od razu zrestartować z nowym obrazem:

```bash
sudo bootc upgrade --apply
```

### Sprawdzenie statusu

```bash
bootc status
```

Wyświetla aktualnie działający obraz, oczekujący obraz (jeśli jest) oraz origin.

### Cofnięcie aktualizacji (rollback)

Jeśli po aktualizacji coś nie działa:

```bash
sudo bootc rollback
```

Przywraca poprzednią wersję obrazu przy następnym restarcie. bootc przechowuje dwie wersje (aktywna + poprzednia).

### Przełączanie edycji

```bash
boobsos-edition status          # pokaż aktualną edycję
boobsos-edition list            # lista dostępnych edycji
boobsos-edition switch dev      # przełącz na edycję DevOps
boobsos-edition switch game     # przełącz na edycję Game
```

Polecenie `boobsos-edition switch` wykonuje `bootc switch` do odpowiedniego obrazu i restartuje system. Katalog `/home` jest współdzielony między edycjami.

---

## CA — zaufanie do rejestru

Rejestr `registry.gitlab.cycr.us` korzysta z certyfikatu TLS wystawionego przez **SSL2BUY EMEA RSA Domain Validation Secure Server CA** (pośredni CA) oraz root **Sectigo Public Server Authentication Root R46**.

Root Sectigo R46 jest stosunkowo nowy (2021) i może nie być obecny w starszych wersjach bundla `ca-certificates`. Dlatego oba certyfikaty CA (pośredni + root) są dołączone bezpośrednio do obrazu BoobsOS jako anchor:

```
/etc/pki/ca-trust/source/anchors/cycr-us-ca.crt
```

Aktywacja (`update-ca-trust`) jest wykonywana w `Containerfile` podczas budowania obrazu. Dzięki temu każde urządzenie z BoobsOS ufał rejestrowi bez dodatkowej konfiguracji.

---

## Pakiety RPM

Pakiety systemowe (aktualizacje RPM) serwowane są z własnego repozytorium:

```
https://repo.cycx.io/fedora/$releasever/$basearch/
```

Repozytorium skonfigurowane jest przez plik `files/etc/yum.repos.d/cycrus.repo` dołączony do obrazu. Pakiety standardowe Fedory dostępne są przez overlay DNF (mechanizm bootc).

---

## Buildy CI i rejestr

Każdy merge/push do brancha `main` w repozytorium `gitlab.cycr.us/fzienowicz/boobsos` uruchamia pipeline CI GitLab, który:

1. Buduje obraz OCI na podstawie `Containerfile`.
2. Pushuje nowy obraz do rejestru `registry.gitlab.cycr.us` z tagami `:latest` i SHA commita.
3. Timer na urządzeniach użytkowników wykrywa nowy digest i pobiera aktualizację.

Buildy planowane (scheduled) uruchamiane są o `05:00 UTC` (edycja DevOps) i `05:30 UTC` (edycje Game), co zapewnia regularne aktualizacje bazowych warstw (upstream UBlue/Fedora).

---

## Podsumowanie

```
Urządzenie → bootc timer → registry.gitlab.cycr.us (nasz rejestr) → nowy obraz
                                      ↑
                              CI GitLab (gitlab.cycr.us)
                              buduje z Containerfile

Pakiety RPM → repo.cycx.io (nasze repo)
```

Żadna aktualizacja nie trafia z zewnętrznych źródeł (ghcr.io, quay.io, Fedora mirrors) — wyłącznie z infrastruktury Cycrus.
