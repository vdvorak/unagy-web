# Frontend rules

Tech-agnostic tvar klientské vrstvy. Hygiena viz `.agentic/constitution.md`.
Stack-specifika viz `stack/web.md`.

## Stack a rendering

Projekt používá **čisté HTML/CSS, žádný build tool, žádný JS framework**.
Soubory se commitují přesně tak, jak se servírují (GitHub Pages).

- **Žádný bundler** (webpack, vite, parcel) — zakázán.
- **Žádný CSS framework** (Bootstrap, Tailwind) — zakázán. Vlastní CSS s proměnnými.
- **Žádný runtime JS framework** (React, Vue, Solid) — zakázán pro tento projekt.
- Minimální vanilla JS povoleno pro UX drobnosti (např. hamburger menu), ne pro logiku.

## Struktura souborů

```
index.html          # hlavní landing stránka
404.html            # custom 404 (GitHub Pages)
css/
  style.css         # hlavní stylesheet
  tokens.css        # CSS custom properties (barvy, spacing, typografie)
img/                # obrázky, QR kódy (SVG preferováno)
```

Žádné adresáře `src/`, `dist/`, `build/` — není co buildovat.

## Styling

- **CSS custom properties** (`tokens.css`) = jediný slovník hodnot (barvy, spacing, radius).
  V CSS NIKDY magic hodnota — vždy `var(--token)`.
- Žádné inline styly v HTML.
- Mobile-first media queries.

## Přístupnost (a11y)

- Sémantický HTML (`<header>`, `<main>`, `<footer>`, `<nav>`).
- Alt texty na všech obrázcích, včetně QR kódů
  (alt = "QR kód ke stažení aplikace Unagy z Google Play").
- Kontrast textu min. WCAG AA (4.5:1 pro normální text).
- Interaktivní prvky dostupné přes klávesnici.

## Externe linky

- Vždy `rel="noopener noreferrer"` na external odkazech (viz constitution security).
- App Store / Google Play linky: `target="_blank"` + výše zmíněný rel.

## SEO

- `<title>` a `<meta name="description">` vyplněny na každé stránce.
- Open Graph tagy (`og:title`, `og:description`, `og:image`) na `index.html`.
- `<html lang="cs">` nastaven.
