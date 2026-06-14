# unagy-web — Project State

Živý stav projektu. Edituje Watson (handoff mode) a orchestrátor.

## Aktuální fokus

**Landing page LIVE** (2026-06-14). Statický web pro Unagy nasazený na
**https://unagy.cz/** (GitHub Pages + Actions, custom doména, HTTPS). Obsah je
zatím **mock s placeholdery**. Brand ve stylu Unagy + companion **Luna** (Rive).
Detail viz `handoffs/2026-06-14-landing-luna.md`.

Žádná otevřená wave. Čeká se na finální vstupy uživatele (store URL, texty, logo).

## Hotové (2026-06-14)
- [x] **Landing page** — `index.html` + `css/` + `404.html`, brand z UnagyDev tokenů
- [x] **GitHub Pages** — repo vdvorak/unagy-web, Actions deploy, unagy.cz, HTTPS (Wedos DNS)
- [x] **Companion Luna** — Rive animace (`assets/luna/`, `js/luna.js`): wave na load,
  idle základ, náhodné variety

## Open Items (placeholdery → produkční obsah)

- [ ] **Store URL** (Google Play + App Store) → nahradit `#TODO-*-url` + reálné QR kódy
- [ ] **Logo** (zatím textové „U")
- [ ] **Finální texty** — hero copy, web-app popis, kontaktní e-mail
- [ ] **OG obrázek** — `og-image.png` 1200×630 (teď SVG placeholder)
- [ ] **robots.txt + sitemap** (alfred-devops)
- [ ] **Odstranit debug** z `js/luna.js` (`?debug=1`) po odsouhlasení tempa Luny
