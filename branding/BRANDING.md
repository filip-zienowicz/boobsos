# BoobsOS — Branding

Tożsamość wizualna BoobsOS, wywodzona z projektu `cycrus-ksef`. Desktopowy
Linux dla DevOps / programistów / IT.

## Logo

- `logo/boobsos-logo.png` — główny znak (512×512, RGBA, przezroczyste tło)
- `logo/boobsos-icon.png` — ikona aplikacji / favicon (512×512)
- `logo/boobsos-apple-icon.png` — ikona dla apple-touch

Motyw: stylizowany łabędź wpisany w heksagon, z gradientem niebiesko-fioletowym.
Heksagon = kafelek/„chip", łabędź = sygnatura marki. Tło zawsze przezroczyste —
znak działa na jasnym i ciemnym motywie.

### Zasady użycia
- Zachowaj margines ochronny ≥ 1/6 szerokości znaku.
- Nie zmieniaj proporcji, nie obracaj, nie dodawaj cieni poza wbudowanym gradientem.
- Na ciemnym tle używaj wersji z przezroczystym tłem (domyślna).
- Minimalny rozmiar czytelny: 32×32 px (favicon), 24×24 px tylko jako monochrom.

## Paleta kolorów

Spójna z `cycrus-ksef` (Tailwind/shadcn, format HSL). Kolor wiodący to niebieski,
akcent cyan, uzupełnienie fiolet — odwzorowuje gradient heksagonu.

### Kolory marki (gradient logo)

| Rola            | HEX       | Uwagi                              |
|-----------------|-----------|------------------------------------|
| Brand Blue      | `#2563EB` | kolor wiodący (primary)            |
| Brand Cyan      | `#2090C0` | akcent / podświetlenia łabędzia    |
| Brand Violet    | `#402090` | dolny biegun gradientu             |
| Hex Mid         | `#314B98` | środek heksagonu                   |

Gradient znaku: `linear-gradient(135deg, #2090C0 0%, #2563EB 45%, #402090 100%)`.

### Motyw jasny (`:root`)

```css
--background: 0 0% 100%;
--foreground: 222.2 84% 4.9%;
--primary: 221.2 83.2% 53.3%;        /* #2563EB */
--primary-foreground: 210 40% 98%;
--secondary: 210 40% 96%;
--muted-foreground: 215.4 16.3% 46.9%;
--accent: 210 40% 96%;
--destructive: 0 84.2% 60.2%;
--border: 214.3 31.8% 91.4%;
--ring: 221.2 83.2% 53.3%;
--radius: 0.5rem;
```

### Motyw ciemny (`.dark`) — domyślny dla desktopu

```css
--background: 222.2 84% 4.9%;
--foreground: 210 40% 98%;
--primary: 217.2 91.2% 59.8%;        /* jaśniejszy niebieski na ciemnym tle */
--primary-foreground: 222.2 47.4% 11.2%;
--secondary: 217.2 32.6% 17.5%;
--muted-foreground: 215 20.2% 65.1%;
--accent: 217.2 32.6% 17.5%;
--destructive: 0 62.8% 30.6%;
--border: 217.2 32.6% 17.5%;
--ring: 224.3 76.3% 48%;
```

## Zastosowanie w dystrybucji (do zrobienia, gdy wybierzemy bazę)

Te elementy będą korzystać z powyższej palety i logo:
- Tapeta pulpitu (gradient niebiesko-fioletowy + znak)
- Ekran logowania (GDM/SDDM/greetd) i splash bootu (Plymouth)
- Motyw GTK/Qt — akcent `#2563EB`, ciemny domyślnie
- Logo w bootloaderze (GRUB/systemd-boot) i instalatorze
- `os-release` / neofetch ASCII art w barwach marki
