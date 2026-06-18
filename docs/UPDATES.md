# Aktualizacje BoobsOS — model i procedury

## Skąd pochodzą aktualizacje

BoobsOS jest oparty na modelu **image-based** (bootc/OCI). Obrazy OCI publikowane są publicznie na **GitHub Container Registry (ghcr.io)** — bez potrzeby logowania. CI GitLab buduje obrazy i pushuje je na ghcr.io.

| Składnik | Źródło (bieżące) | Uwagi |
|----------|-----------------|-------|
| Obrazy OCI (system) | `ghcr.io/filip-zienowicz/boobsos` | Publiczny rejestr, bez pull-secret |
| Obraz edycji Game | `ghcr.io/filip-zienowicz/boobsos-game` | |
| Obraz edycji Game (NVIDIA) | `ghcr.io/filip-zienowicz/boobsos-game-nvidia` | |
| Pakiety RPM | `repo.cycx.io/fedora/$releasever/$basearch/` | Skonfigurowane przez `cycrus.repo` |

---

## Model aktualizacji obrazu OCI

### Auto-aktualizacje (timer)

W każdym obrazie BoobsOS włączony jest `bootc-fetch-apply-updates.timer` (usługa systemd). Timer działa w tle:

1. Regularnie sprawdza, czy w rejestrze (`ghcr.io`) dostępny jest nowy obraz.
2. Jeśli tak — pobiera go i przygotowuje do zastosowania.
3. Przy następnym **restarcie systemu** nowy obraz zostaje aktywowany atomowo.

Nie jest wymagana żadna akcja ze strony użytkownika. Aktualizacje są atomowe — w razie problemu system można cofnąć (patrz: rollback).

### Origin obrazu

Przy instalacji BoobsOS (z ISO lub przez `bootc switch`) origin systemu ustawiany jest na odpowiedni obraz na ghcr.io:

```
ghcr.io/filip-zienowicz/boobsos:latest          # edycja DevOps
ghcr.io/filip-zienowicz/boobsos-game:latest     # edycja Game
ghcr.io/filip-zienowicz/boobsos-game-nvidia:latest  # edycja Game + NVIDIA
```

Timer i `bootc upgrade` zawsze operują względem tego originu. Rejestr jest publiczny — nie jest wymagane logowanie ani pull-secret.

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

`ghcr.io` (GitHub Container Registry) korzysta z publicznie zaufanego certyfikatu TLS — nie wymaga żadnego dodatkowego CA anchor po stronie klienta. Standardowy `ca-certificates` w systemie wystarczy.

> **Uwaga wewnętrzna:** Rejestr `gitlab.cycr.us:5050` (używany przez CI jako mirror) korzysta z certyfikatu wystawionego przez **SSL2BUY EMEA RSA Domain Validation Secure Server CA** / root **Sectigo Public Server Authentication Root R46**. Certyfikaty CA są dołączone do obrazu jako anchor (`/etc/pki/ca-trust/source/anchors/cycr-us-ca.crt`) na wypadek bezpośredniego dostępu do GitLab registry — nie jest to wymagane przy bieżącym originie ghcr.io.

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
2. Pushuje nowy obraz do `ghcr.io/filip-zienowicz/boobsos` z tagami `:latest` i SHA commita.
3. Timer na urządzeniach użytkowników wykrywa nowy digest i pobiera aktualizację.

Buildy planowane (scheduled) uruchamiane są o `05:00 UTC` (edycja DevOps) i `05:30 UTC` (edycje Game), co zapewnia regularne aktualizacje bazowych warstw (upstream UBlue/Fedora).

---

## Podsumowanie

```
Urządzenie → bootc timer → ghcr.io/filip-zienowicz/boobsos (publiczny) → nowy obraz
                                      ↑
                              CI GitLab (gitlab.cycr.us)
                              buduje z Containerfile i pushuje na ghcr.io

Pakiety RPM → repo.cycx.io (nasze repo)
```

Obrazy OCI pochodzą z `ghcr.io` (publiczny, bez logowania). Pakiety RPM — wyłącznie z infrastruktury Cycrus (`repo.cycx.io`).

---

## Przyszłość / opcja wewnętrzna: migracja originu na GitLab registry

Docelowo możliwa jest zmiana originu na rejestr self-hosted `gitlab.cycr.us:5050`, co pozwoliłoby utrzymać cały łańcuch dystrybucji wewnątrz infrastruktury Cycrus. **Warunek konieczny do spełnienia przed wdrożeniem:**

- **(a)** rejestr GitLab jest publiczny (projekt ustawiony jako „public" lub rejestr dostępny anonimowo), **lub**
- **(b)** skopowany, niemożliwy do odczytania token z ograniczonymi uprawnieniami (read-only, scoped deploy token) dostarczany jest do urządzeń klienckich za pośrednictwem **zabezpieczonego kanału ISO** (nie public repo, nie publiczny obraz).

**Reguła bezpieczeństwa — bezwzględna:** żaden pull-secret, deploy token ani `glpat-*` nie może być wbudowany w publiczny obraz OCI ani commitowany do publicznego repozytorium. Naruszenie tej zasady skutkuje publicznym ujawnieniem danych uwierzytelniających.
