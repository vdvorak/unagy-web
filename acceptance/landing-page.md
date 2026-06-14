# Acceptance criteria — Landing Page (unagy.cz)

Každé kritérium musí být ověřitelné nezávislým agentem (joey-qa) nebo manuálním testem.

---

## A. Obsah a sekce

- [ ] A1. Stránka obsahuje hero sekci s názvem aplikace a stručným popisem (min. 1 věta).
- [ ] A2. Stránka obsahuje download sekci s odkazem na Google Play a odkazem na App Store.
- [ ] A3. Download sekce obsahuje QR kód pro Google Play a QR kód pro App Store (ne placeholder v produkci).
- [ ] A4. Stránka obsahuje odkaz na https://app.unagy.cz (ve vlastní sekci nebo v hero).
- [ ] A5. Stránka obsahuje footer s copyright textem.
- [ ] A6. Žádný viditelný placeholder text (např. "TODO", "PLACEHOLDER", "bude doplněno") nesmí být přítomen na produkční verzi.

## B. Odkazy a bezpečnost

- [ ] B1. Odkaz na Google Play otevírá správnou store URL aplikace Unagy.
- [ ] B2. Odkaz na App Store otevírá správnou store URL aplikace Unagy.
- [ ] B3. Odkaz na app.unagy.cz odkazuje na https://app.unagy.cz.
- [ ] B4. Všechny externí odkazy (store URL, app.unagy.cz) mají atribut `rel="noopener noreferrer"`.
- [ ] B5. V HTML není žádný inline `<script>` element.
- [ ] B6. V `<head>` je přítomen `<meta http-equiv="Content-Security-Policy" ...>` tag.

## C. SEO a meta

- [ ] C1. `<title>` tag je vyplněn a smysluplně popisuje stránku (obsahuje název "Unagy").
- [ ] C2. `<meta name="description">` je přítomen a neprázdný.
- [ ] C3. Open Graph tagy jsou přítomny: `og:title`, `og:description`, `og:url`.
- [ ] C4. `<html lang="cs">` je nastaven.

## D. Přístupnost (a11y)

- [ ] D1. Každý QR kód obrázek má neprázdný `alt` atribut popisující jeho obsah (např. "QR kód pro stažení na Google Play").
- [ ] D2. Store badges mají neprázdný `alt` atribut.
- [ ] D3. Stránka prochází bez chyb nástrojem axe nebo Lighthouse Accessibility (skóre >= 90).
- [ ] D4. Kontrast textu vůči pozadí splňuje WCAG AA (4.5:1 pro normální text).

## E. Responsivita

- [ ] E1. Stránka se korektně zobrazuje na šířce 375px (iPhone SE) — žádný horizontální scroll, žádný přetékající obsah.
- [ ] E2. Stránka se korektně zobrazuje na šířce 768px (tablet).
- [ ] E3. Stránka se korektně zobrazuje na šířce 1280px (desktop).
- [ ] E4. QR kódy jsou viditelné a dostatečně velké na mobilním zobrazení (min. 150×150px).

## F. Výkon

- [ ] F1. Lighthouse Performance skóre >= 90 na mobilní emulaci (throttled 4G).
- [ ] F2. Stránka neobsahuje žádné broken image (404 na img soubory).

## G. Technická správnost

- [ ] G1. HTML validátor (W3C) nehlásí chyby (warnings jsou přijatelné).
- [ ] G2. Stránka se načítá přes HTTPS na produkční doméně unagy.cz.
- [ ] G3. Soubor `CNAME` v root repozitáře obsahuje `unagy.cz`.
