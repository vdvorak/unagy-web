---
handoff: landing-page + companion Luna
date: 2026-06-14
from: orchestrator (Claude)
status: LIVE (mock obsah)
---

# Handoff — Landing page Unagy + Luna

## Co je hotové

**Statický landing je nasazený a živý na https://unagy.cz/** (HTTPS, Let's Encrypt).

- **Repo:** https://github.com/vdvorak/unagy-web (public, owner vdvorak)
- **Hosting:** GitHub Pages přes GitHub Actions (`.github/workflows/deploy.yml`),
  custom doména `unagy.cz` (CNAME), Enforce HTTPS zapnuto.
- **DNS:** doména u **Wedos**, A záznamy (apex) → GitHub Pages IP (185.199.108–111.153).
  Wedos publikuje DNS změny dávkově (~hodinová prodleva).
- **Fallback URL:** https://vdvorak.github.io/unagy-web/ (přesměruje na unagy.cz).

### Obsah stránky
- Brand ve stylu Unagy: warm dark téma z `../UnagyDev/design/manual/tokens.css`
  (espresso `#1f1814`, terracotta `#d08763`), fonty Fraunces + Manrope.
- Sekce: hero s **Lunou**, download (QR + store tlačítka), odkaz na `app.unagy.cz`, footer.
- `index.html`, `css/tokens.css`, `css/style.css`, `404.html`.

### Luna (companion)
- Skutečná Rive animace: `assets/luna/luna.riv` (z UnagyDev companions/default),
  runtime `@rive-app/canvas@2` z CDN, řízeno `js/luna.js` (vanilla, verzováno `?v=N`).
- Chování: na load **wave**, pak **idle** základ, po 2,5–5 s náhodně
  `happy`/`wave`/`eat-cookie`/`breathIN-OUT`, vždy dohraje do konce (onStop automat).
- CSS fallback (pulzující blob) když JS/Rive nenaběhne.
- Postava `Orson` + výraz `Neutral` nastaveny napevno přes data binding (RJ_Data),
  bez uživatelského pickeru.

### Klíčová zjištění o luna.riv (pro budoucí úpravy)
- artboard: `00main`; state machine: `Animations`.
- animace: `idle`, `wave`, `happy`, `eat-cookie`, `breathIN-OUT`, `walk_front`,
  `sad`, `sadIntense`, `angry`, `angryIntense`, `scared_loop`.
- data binding view model `RJ_Data`: enum `CharacterSelect` (Orson/Merv),
  enum `FaceEmotion` (Neutral/Happy/Sad/Eating/Angry/Scared…).
- CSP musí mít `'wasm-unsafe-eval'` (Rive běží na WASM) — viz `index.html`.

## Otevřené / TODO (placeholdery — blokují produkční obsah)

- [ ] **Google Play URL** + **App Store URL** → nahradit `#TODO-*-url` + vygenerovat reálné QR
- [ ] **Logo** (zatím textové „U")
- [ ] **Finální hero copy** (teď rozumný placeholder, neutrální tón)
- [ ] **Web-app popis** (1 věta)
- [ ] **Kontaktní e-mail** (footer, teď `TODO@unagy.cz`)
- [ ] **OG image** (PNG 1200×630, teď SVG placeholder)
- [ ] **robots.txt + sitemap** (alfred-devops)
- [ ] **Odstranit debug** z `js/luna.js` (`?debug=1` panel) až bude tempo Luny odsouhlasené

## Pozn. pro další práci
- Úprava `js/luna.js` → vždy bumpni `?v=N` v `<script src>` v `index.html`
  (jinak prohlížeč servíruje starou verzi z cache — opakovaně nás to zdrželo).
- Ladění Luny: interval `VARIETY_MIN/MAX_MS`, sada `VARIETY`.
