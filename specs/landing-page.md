# Landing Page — unagy.cz

## Cíl

Jediná statická stránka na unagy.cz, která představí aplikaci Unagy (co to je a pro koho),
nabídne přímé stažení mobilní appky (Google Play, App Store) včetně QR kódů a odkáže
uživatele na webovou verzi na app.unagy.cz.

## Scope

**In:**
- Sekce hero — název, stručný popis aplikace, hlavní CTA
- Sekce download — QR kódy + textové odkazy na Google Play a App Store
- Sekce web-app — odkaz/tlačítko na app.unagy.cz
- Footer — copyright, případně odkaz na kontakt
- SEO: `<title>`, `<meta description>`, Open Graph tagy
- Responsivita: mobile-first, cíl iOS Safari 15+, Android Chrome 105+, desktop Chrome/Firefox/Edge
- Základní a11y: alt texty na QR kódech a store badges, sémantický HTML, dostatečný kontrast

**Out:**
- Žádný backend, žádné formuláře, žádné API
- Žádná analytika (rozhodnutí při přidání: cookie consent povinný)
- Žádný CMS; obsah editován přímo v HTML
- Žádná vícejazyčná verze (cs only)
- Žádný JS framework ani build tool
- Žádná dílčí podstránka (robots.txt, sitemap jsou deployment detail — Alfred)

## Sekce stránky

### 1. Hero
- Název aplikace a logo (viz `Potřebné vstupy #3`)
- Stručný popis (1–3 věty): co Unagy je a pro koho; tón: lidský, hřejivý, bezpečný — ne klinický
  (viz brand z UnagyDev: "hřejivý minimalismus")
- CTA tlačítka: "Stáhnout pro Android" a "Stáhnout pro iOS" — scrollují do sekce download
  nebo odkazují přímo na store URL

### 2. Download
- QR kód pro Google Play (SVG/PNG, generovaný staticky) + přímý textový odkaz
- QR kód pro App Store (SVG/PNG, generovaný staticky) + přímý textový odkaz
- Store badges (Google Play badge, App Store badge) s alt textem
- Fallback text pro desktop: "Nemáš mobil po ruce? Použij webovou verzi."

### 3. Web App
- Tlačítko / výrazný odkaz na https://app.unagy.cz
- Krátký popisek (1 věta): co na web-app uživatel najde

### 4. Footer
- Copyright (rok, název)
- Volitelně: kontaktní e-mail nebo odkaz (viz `Potřebné vstupy #4`)

## Acceptance criteria

Viz `acceptance/landing-page.md`.

## Edge cases & otevřené otázky

- **QR kódy bez platné store URL:** dokud nejsou finální URL, QR kódy budou placeholder SVG
  s viditelným textem "QR kód bude doplněn". Tento stav nesmí projít do produkce.
- **Redirect na app.unagy.cz:** spec definuje pouze přímý odkaz `<a href="...">`.
  Pokud bude žádoucí meta-refresh nebo JS redirect z unagy.cz/app → app.unagy.cz,
  rozhodnutí patří do nové spec / addendum.
- **Dark mode:** není v scope MVP; rozhodnutí při přidání.

## Potřebné vstupy od uživatele (OPEN)

| # | Vstup | Blokuje |
|---|---|---|
| 1 | **Google Play URL** aplikace Unagy (placeholder: `https://play.google.com/store/apps/details?id=TODO`) | QR kód sekce download, store odkaz |
| 2 | **App Store URL** aplikace Unagy (placeholder: `https://apps.apple.com/app/TODO`) | QR kód sekce download, store odkaz |
| 3 | **Logo / brand assety** (SVG nebo PNG logo Unagy) | Hero sekce; bez loga peter-web použije textový název |
| 4 | **Kontaktní e-mail nebo URL** pro footer (nebo potvrdit: footer bez kontaktu) | Footer |
| 5 | **Finální marketingový text** popisující Unagy pro landing (hero + web-app popisek); zatím lze použít placeholder z UnagyDev constituce jako základ | Hero sekce |

Dokud vstupy #1 a #2 nejsou k dispozici, peter-web implementuje s placeholdery
a stránka **nesmí jít do produkce** (gate: joey-qa ověří, že žádný placeholder URL nezůstal).

## Decided

- Žádný build tool ani JS framework — vyplývá z PROJECT-CONSTITUTION + stack/web.md.
- QR kódy jsou statické soubory (SVG/PNG), žádná runtime QR knihovna — dle constitution.
- External linky (store, app.unagy.cz) s `rel="noopener noreferrer"` — dle constitution.
- CSP přes `<meta>` tag v `<head>` (GitHub Pages nepodporuje HTTP hlavičky) — dle stack/web.md.
- Jednojazyčná cs verze; i18n není plánováno — dle constitution.
- `has_ui: true` — stránka má vizuální výstup; peter-web implementuje UI ze spec (derive mode).
