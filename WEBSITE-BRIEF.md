# BoobsOS — Brief dla strony WWW

Samodzielny dokument dla agenta budującego stronę. Zawiera wszystkie cechy
produktu, tożsamość wizualną i wskazówki contentowe. Źródła: `ARCHITECTURE.md`,
`branding/BRANDING.md`, `README.md`, `Containerfile`.

---

## 1. Czym jest BoobsOS (one-liner + opis)

**One-liner:** Desktopowy Linux dla DevOps, programistów i inżynierów IT — gotowy do pracy zaraz po instalacji.

**Opis (1 akapit):** BoobsOS to nowoczesna dystrybucja Linuksa oparta na Fedorze
(model atomowy bootc/OCI), nastawiona na pracę DevOps/dev/IT. Wszystkie narzędzia
— kontenery, Kubernetes, IaC, chmura, sieć — są wbudowane i skonfigurowane z pudełka.
System dostarczany jest jako wersjonowany obraz: aktualizacje są atomowe, a w razie
problemu jeden `bootc rollback` cofa system do poprzedniego stanu. Koniec z
„rozjeżdżaniem się" systemu i ręcznym dłubaniem w konfiguracji.

**Propozycje tagline (do wyboru przez stronę):**
- „Twój DevOps desktop. Włącz i pracuj."
- „Fedora atomic, naładowana narzędziami DevOps."
- „Cały toolchain. Zero setupu. Pełny rollback."
- „Linux, który jest gotowy zanim Ty będziesz."

---

## 2. Tożsamość wizualna

### Logo
- Główny znak: `branding/logo/boobsos-logo.png` (512×512, RGBA, przezroczyste tło)
- Ikona / favicon: `branding/logo/boobsos-icon.png`
- Apple touch icon: `branding/logo/boobsos-apple-icon.png`
- Motyw znaku: stylizowany **łabędź wpisany w heksagon**, gradient niebiesko-fioletowy.
  Heksagon = „chip"/kafelek, łabędź = sygnatura marki.
- Tło zawsze przezroczyste — działa na jasnym i ciemnym motywie. Margines ochronny ≥ 1/6 szerokości.

### Paleta kolorów (dokładne wartości)

| Rola         | HEX       | HSL                  | Użycie na stronie                    |
|--------------|-----------|----------------------|--------------------------------------|
| Brand Blue   | `#2563EB` | `221 83% 53%`        | kolor wiodący, przyciski, linki      |
| Brand Cyan   | `#2090C0` | `197 71% 44%`        | akcenty, podświetlenia, gradient góra|
| Brand Violet | `#402090` | `258 64% 34%`        | gradient dół, akcenty kontrastowe    |
| Hex Mid      | `#314B98` | `224 51% 39%`        | tła pośrednie                        |

**Gradient marki (hero, przyciski, akcenty):**
`linear-gradient(135deg, #2090C0 0%, #2563EB 45%, #402090 100%)`

**Motyw strony: domyślnie CIEMNY** (spójnie z systemem). Sugerowane tła:
- tło główne: bardzo ciemny granat `hsl(222 84% 5%)` (`#09090F`-ish)
- powierzchnie/karty: `hsl(217 33% 17%)`
- tekst: `hsl(210 40% 98%)`
- obramowania: `hsl(217 33% 17%)`

Pełne zmienne CSS (light + dark, format Tailwind/shadcn HSL) są w `branding/BRANDING.md` — można je wziąć 1:1 do Tailwinda.

### Typografia (sugestia)
- Nagłówki: nowoczesny grotesk (Inter, Geist, Space Grotesk).
- Kod/terminal: font monospace (JetBrains Mono, Fira Code) — strona powinna pokazywać komendy.
- Waga nagłówków 600, line-height ~1.25.

---

## 3. Grupa docelowa

- **DevOps / SRE / Platform engineers** — chcą gotowy toolchain (k8s, IaC, chmura) bez setupu.
- **Programiści / inżynierowie IT** — środowisko dev od ręki, izolacja przez kontenery.
- **Power-userzy Linuksa** ceniący reprodukowalność i atomowe aktualizacje.

Ton: techniczny, konkretny, dla profesjonalistów. Bez korpo-bełkotu. Można lekki luz (nazwa marki jest przymrużeniem oka), ale produkt traktujemy serio.

---

## 4. Kluczowe wyróżniki (value props — sekcje „dlaczego BoobsOS")

1. **Gotowy do pracy z pudełka** — kompletny zestaw DevOps preinstalowany i skonfigurowany. Zero „dzień zero" setupu.
2. **Atomowy i niezniszczalny** — aktualizacje jako całe obrazy; `bootc rollback` cofa system jednym poleceniem. System się nie „rozjeżdża".
3. **Reprodukowalny** — cały OS zdefiniowany jak `Dockerfile` (`Containerfile`). Ten sam obraz na każdej maszynie. Idealne dla flot/zespołów.
4. **Oparty na Fedorze** — świeże jądro i toolchainy, ekosystem RPM + Flatpak (Flathub) + Homebrew.
5. **Container-native** — Docker i Podman obok siebie, distrobox/toolbox do izolacji środowisk.
6. **GNOME, ciemny motyw, własny branding** — czysty, nowoczesny pulpit Wayland.

---

## 5. Jak to działa (sekcja techniczna na stronę)

System = **wersjonowany obraz OCI** budowany z oficjalnego obrazu Fedora bootc
(Universal Blue `base-main`). Na bazę nakładamy warstwę z narzędziami i brandingiem
przez `Containerfile`, budujemy w CI i publikujemy do rejestru. Z obrazu generujemy
instalowalne ISO przez `bootc-image-builder`.

Przepływ (dobry materiał na diagram/animację):
```
Fedora bootc (baza)  →  Containerfile (warstwa BoobsOS)  →  build w CI
   →  obraz OCI w rejestrze  →  ISO / instalacja  →  bootc upgrade / rollback
```

Pojęcia do wytłumaczenia na stronie: **bootc** (atomowy OS z obrazu kontenera),
**aktualizacje atomowe**, **rollback**, **rebase** (przejście z istniejącej Fedory Atomic jednym poleceniem).

---

## 6. Pełna lista funkcji / narzędzi „z pudełka"

> To są realne pakiety z `Containerfile`. Idealne na sekcję „What's included" (siatka kategorii z ikonami).

| Kategoria | Narzędzia |
|-----------|-----------|
| **Kontenery** | Docker CE + compose, Podman, Buildah, Skopeo, Distrobox, Toolbox |
| **Kubernetes** | kubectl, Helm, k9s, kubectx/kubens, Kustomize, stern, kind |
| **IaC / automatyzacja** | Terraform, OpenTofu, Ansible |
| **Chmura** | AWS CLI v2, Azure CLI (az), Google Cloud CLI (gcloud) |
| **Sekrety / krypto** | HashiCorp Vault, SOPS, age + age-plugin-yubikey (YubiKey), GnuPG, pass |
| **Git i hosting** | git, git-lfs, GitHub CLI (gh), GitLab CLI (glab), lazygit |
| **Shell / terminal** | zsh, tmux, Starship (prompt), fastfetch |
| **CLI UX** | neovim, fzf, ripgrep, bat, eza, fd, zoxide, jq, yq, git-delta, direnv, htop, btop, ncdu, tree |
| **Build / języki** | gcc/make (@development-tools), Go, Python 3, mise (manager wersji: node/ruby/itd.) |
| **Sieć** | nmap, tcpdump, mtr, wireshark-cli (tshark), httpie, wireguard-tools, iperf3, socat, traceroute, ethtool, iftop, bind-utils (dig), whois, sshpass |
| **GUI / aplikacje** | Flathub włączony — VSCode, przeglądarki, narzędzia przez `flatpak install` |
| **Środowisko** | GNOME (Wayland), domyślnie ciemny motyw, branding BoobsOS |

Cechy systemowe:
- **Aktualizacje atomowe** (`bootc upgrade`) i **rollback** (`bootc rollback`).
- **Rebase z Fedory Atomic** jednym poleceniem (`bootc switch`).
- **Flatpak + Flathub** dla aplikacji GUI; **Homebrew** dla narzędzi CLI użytkownika.
- **Docker i Podman** współistnieją; `docker.socket` i `podman.socket` włączone.

---

## 7. Instalacja (sekcja „Get started")

Trzy ścieżki — każda nadaje się na blok z komendą do skopiowania:

1. **Instalacja od zera (ISO):** pobierz ISO → zainstaluj jak każdy system (instalator Anaconda).
2. **Rebase z istniejącej Fedory Atomic** (Silverblue/Kinoite/Bazzite itp.):
   ```bash
   sudo bootc switch ghcr.io/filip-zienowicz/boobsos:latest
   ```
   restart → system działa jako BoobsOS.
3. **Wypróbuj w VM:** wygeneruj qcow2/ISO przez `bootc-image-builder`, odpal w QEMU/virt-manager.

Aktualizacja: `sudo bootc upgrade` · Cofnięcie: `sudo bootc rollback`.

> Hosting kodu: **GitLab** (gitlab.cycr.us/fzienowicz/boobsos). Obrazy publikowane na `ghcr.io/filip-zienowicz/boobsos` (publiczne, bez logowania). CI GitLab buduje obrazy i mirroruje na ghcr.io.

---

## 8. Status / roadmap (na sekcję „Roadmap" lub „Status")

| Faza | Opis | Status |
|------|------|--------|
| F0 | Branding (logo, paleta) | ✅ |
| F1 | Szkielet repo + Containerfile | ✅ |
| F2 | Pakiety DevOps + Flathub | ✅ |
| F3 | Branding w systemie (Plymouth, GDM, tapeta) | w toku |
| F4 | CI + publikacja obrazu do rejestru | planowane |
| F5 | Generowanie ISO, test w VM | planowane |
| F6 | Dokumentacja użytkownika | planowane |

Projekt jest **we wczesnej fazie** — strona może mieć status „early access / w budowie" i CTA do zapisu na listę / repo GitLab.

---

## 9. Sugerowana struktura strony (dla agenta)

1. **Hero** — logo, nazwa, tagline, gradient marki, dwa CTA: „Pobierz / Wypróbuj" + „Zobacz na GitLab". Tło: ciemne z gradientem niebiesko-fioletowym.
2. **Dlaczego BoobsOS** — 3–6 kafli z value props (sekcja 4).
3. **Jak to działa** — diagram przepływu bootc (sekcja 5), wyjaśnienie atomowości i rollbacku.
4. **Co jest z pudełka** — siatka kategorii narzędzi z ikonami (sekcja 6). Mocny punkt wizualny.
5. **Get started** — trzy ścieżki instalacji z blokami komend do kopiowania (sekcja 7).
6. **Roadmap / status** — tabela faz (sekcja 8).
7. **FAQ** — zalążki niżej.
8. **Stopka** — link GitLab, licencja, „zbudowane na Fedorze / bootc".

Elementy wizualne, które pasują: bloki terminala z komendami (mono font, kropki okna),
animowany gradient w hero, „chip"/heksagon jako motyw przewodni (z logo), ciemny motyw z neonowo-niebieskimi akcentami.

---

## 10. FAQ (zalążki)

- **Czym różni się od zwykłej Fedory?** Preinstalowany toolchain DevOps + atomowy model bootc + rollback + własny branding.
- **Czy mogę instalować własne pakiety?** Tak: warstwowo (rpm), Flatpak (GUI), Homebrew (CLI), oraz kontenery (distrobox/toolbox).
- **Czy stracę dane przy aktualizacji?** Nie — katalog domowy jest trwały; aktualizuje się obraz systemu, z możliwością rollbacku.
- **Na jakim sprzęcie działa?** x86_64 (aarch64 planowane — patrz uwagi o repo chmury).
- **Czy to oficjalny produkt Fedora?** Nie — to niezależna dystrybucja zbudowana na Fedorze.

---

## 11. Co przekazać web-agentowi w pliku/repo

- Logo: `branding/logo/boobsos-logo.png` (+ icon, apple-icon).
- Pełne zmienne kolorów CSS: `branding/BRANDING.md`.
- Ten brief: `WEBSITE-BRIEF.md`.
- **Język strony:** polski (produkt i dokumentacja są po polsku). W razie potrzeby wersja EN jako druga.
- **Tech sugerowany dla strony:** dowolny statyczny/SSR (Next.js, Astro), Tailwind + paleta z BRANDING.md, ciemny motyw domyślnie.
