# CLAUDE.md — BoobsOS

## O projekcie

**BoobsOS** to desktopowa dystrybucja Linuksa nastawiona na pracę DevOps,
programistów i ogólnie IT. Cel: gotowe do pracy środowisko (narzędzia dev,
konteneryzacja, chmura, CI/CD) bez rozgrzebywania konfiguracji.

**Baza dystrybucji: jeszcze nie wybrana** — kandydaci: Fedora, RHEL, Debian, Arch.
Decyzja jest otwarta; do czasu jej podjęcia nie zakładaj konkretnego menedżera
pakietów ani systemu budowania ISO w trwałych plikach.

### Branding

Tożsamość wizualna w `branding/` (logo + paleta), wywodzona z projektu
`cycrus-ksef`. Szczegóły: `branding/BRANDING.md`.
- Znak: łabędź w heksagonie, gradient niebiesko-fioletowy, przezroczyste tło.
- Kolor wiodący: `#2563EB` (niebieski), akcent `#2090C0` (cyan), fiolet `#402090`.
- Motyw domyślny: ciemny.

## Model Strategy

Główny agent (Opus) zarządza, deleguje i syntetyzuje. Nie wykonuje pracy bezpośrednio jeśli można ją oddać subagentowi.

### Podział modeli

**Opus (orchestrator)** — tylko:
- Planowanie i dekompozycja zadań
- Delegowanie do subagentów
- Synteza wyników, decyzje architektoniczne
- Code review, krytyczne zmiany w produkcji

**Sonnet (subagent)** — domyślny do pracy:
- Implementacja kodu, refactoring
- Pisanie testów, debugowanie
- Analiza większych plików/repo
- Złożone zapytania SQL, integracje API

**Haiku (subagent)** — szybkie i tanie:
- Proste edycje, zmiana nazw, formatowanie
- Czytanie/streszczanie plików
- Grep, wyszukiwanie w kodzie
- Generowanie boilerplate, prostych testów jednostkowych
- Sprawdzanie składni, linting fix

## Zasady delegacji

1. **Zawsze pytaj: czy to musi robić Opus?** Jeśli nie — deleguj.
2. **Równolegle, nie sekwencyjnie** — jeśli zadania są niezależne, odpal subagentów równocześnie.
3. **Haiku first** dla prostych odczytów/wyszukiwań. Eskaluj do Sonneta tylko jeśli Haiku nie wystarcza.
4. **Sonnet do pisania kodu** chyba że zmiana jest trywialna (wtedy Haiku) lub krytyczna/architektoniczna (wtedy Opus).
5. **Opus tylko syntetyzuje** — czyta wyniki subagentów, podejmuje decyzje, pisze finalny output.

## Śledzenie zmian i stan pracy

Cel: w razie zmiany/wymiany agenta (rotacja modelu, restart sesji, przejęcie zadania przez innego subagenta) następny agent musi się szybko odnaleźć w kontekście.

1. **Sprawdzaj historię zmian** — przed edycją pliku przejrzyj jego ostatnie zmiany (`git log`, `git diff`, `git blame`), żeby zrozumieć intencję poprzednich zmian i nie cofnąć cudzej pracy.
2. **Zapisuj stan pracy** — utrzymuj bieżący stan zadania (co zrobione, co w toku, co następne) w trwałym miejscu, np. `PROGRESS.md` lub sekcji TODO, a nie tylko w kontekście sesji.
3. **Dokumentuj zmiany** — każdą istotną zmianę opisuj zwięźle (co, dlaczego, gdzie), żeby kolejny agent mógł kontynuować bez rekonstrukcji decyzji.
4. **Commituj logicznymi krokami** — małe, opisowe commity zamiast jednego wielkiego; ułatwiają rollback i odtworzenie toku pracy.
5. **Notuj otwarte wątki** — niedokończone kroki, znane problemy, podjęte założenia zapisuj jawnie, żeby przejmujący agent znał punkt wejścia.

## Przykłady (kontekst BoobsOS)

- "Znajdź gdzie ustawiamy kolor akcentu motywu" → Haiku
- "Wygeneruj listę pakietów do profilu DevOps" → Haiku
- "Napisz skrypt budujący ISO / konfigurację Plymouth" → Sonnet
- "Zintegruj motyw GTK/Qt z paletą marki" → Sonnet
- "Wybierz bazę dystrybucji (Fedora/Debian/Arch) — trade-offy" → Opus (decyzja), Sonnet (research)
- "Zaprojektuj strukturę repo i pipeline budowania ISO" → Opus (planuje), Sonnet (implementuje)
- "Popraw literówki w komentarzach / opisach pakietów" → Haiku
- "Review profilu instalatora przed wydaniem" → Opus
