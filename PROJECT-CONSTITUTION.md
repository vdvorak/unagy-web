# unagy-web — Project Constitution

> Projektová ústava (CO projekt je). Doplňuje universal `.agentic/constitution.md`
> (JAK agenti fungují). Změna = L3.

## Vize a mise

Statický landing a referenční web pro mobilní aplikaci **Unagy** na doméně **unagy.cz**.

Cíle webu:
- Prezentovat aplikaci Unagy a její hodnotu pro uživatele.
- Poskytnout QR kódy a přímé odkazy ke stažení z Google Play a App Store.
- Přesměrovat/odkázat uživatele na webovou verzi aplikace na **app.unagy.cz**.

Projekt pokrývá POUZE landing unagy.cz. Samotná aplikace (mobil + web) je oddělený
projekt a repo (../UnagyDev).

## Hodnoty

- **Jednoduchost** — žádná zbytečná vrstva. Čisté HTML/CSS, žádný build tool,
  žádný JS framework. Soubory se commitují přesně tak, jak se servírují.
- **Spolehlivost** — statický web na GitHub Pages; žádný runtime server, žádné SPF.
- **Srozumitelnost** — obsah jasný pro koncového uživatele; CTA (stažení, web app)
  viditelné a funkční na všech zařízeních.

## Cílová skupina

Koncoví uživatelé aplikace Unagy — primárně mobilní uživatelé (iOS, Android),
sekundárně desktop prohlížeč.

## Co projekt JE / NENÍ

**JE:**
- Statický landing/referenční web (HTML/CSS)
- Hosting na GitHub Pages + custom doména unagy.cz
- QR kódy a deep-linky na app stores
- Odkaz/redirect na app.unagy.cz

**NENÍ:**
- Samotná Unagy aplikace (to je ../UnagyDev)
- Web app s logikou (žádná autentizace, žádná DB, žádné API)
- CMS (obsah je statický, editovaný přímo v HTML/CSS)
- Vícejazyčný web (jednojazyčná cs verze; i18n se neplánuje)

## Nefunkční požadavky (NFR)

- **Výkon:** Statické soubory; žádný build step. Page load pod 2s na 4G.
- **SEO:** Správné `<meta>` tagy, Open Graph, srozumitelné URL.
- **Bezpečnost:** HTTPS (GitHub Pages zajišťuje), CSP header pokud Pages umožňuje,
  žádné inline JS, external linky s `rel="noopener noreferrer"`.
- **Responsivita:** Mobile-first design; korektní zobrazení na iOS Safari, Android Chrome,
  desktop Chrome/Firefox.
- **Přístupnost:** Základní a11y — alt texty na obrázcích (QR kódy), kontrast,
  sémantický HTML.
- **Compliance:** Žádná osobní data, žádné cookies → GDPR není kritické.
  Pokud se přidá analytics → cookie consent povinný (rozhodnutí při přidání).

## Doménová security pravidla

- External linky (app stores, app.unagy.cz) vždy `rel="noopener noreferrer"`.
- Žádný inline script. Žádné third-party skripty bez vědomého rozhodnutí (+ cookie consent).
- QR kódy generovány staticky (obrázky nebo SVG) — žádná runtime QR knihovna.

## Delivery topologie

- **Stack:** čisté HTML/CSS, žádný build tool, žádný framework
- **Hosting:** GitHub Pages + custom doména unagy.cz
- **CI/CD:** GitHub Actions pro deploy (Alfred)
- **Klienti:** web (static HTML) — žádný server, žádná DB, žádné API
- **Design source:** `derive` — peter-web staví UI rovnou ze specu (solo mode)
