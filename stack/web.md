# Stack — web (plain HTML/CSS + GitHub Pages)

Tech volba pro unagy.cz landing page. Vlastní Ted (architektura) + Alfred (deploy).

---

## Base: plain HTML/CSS

- **Žádný build tool.** Soubory se commitují přesně tak, jak je prohlížeč dostane.
- **Žádný JS framework.** Vanilla JS povoleno jen pro drobné UX (toggles); žádná logika.
- **Žádný CSS framework.** Vlastní CSS s CSS custom properties.
- HTML5, CSS3. Cílové prohlížeče: iOS Safari 15+, Android Chrome 105+, desktop Chrome/Firefox/Edge (LTS).

## Deploy: GitHub Pages + custom doména

- Repo: GitHub (`master` nebo `main` branch → Pages)
- Custom doména: `unagy.cz` (CNAME soubor v repo root)
- HTTPS: automaticky zajišťuje GitHub Pages (Let's Encrypt)
- Deploy: GitHub Actions workflow (`alfred-devops` vlastní `.github/workflows/`)

### GitHub Actions pipeline

```yaml
# .github/workflows/deploy.yml (Alfred seeduje)
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./        # nebo podsložka, pokud projekt přejde na build
          cname: unagy.cz
```

Alternativa: GitHub Pages direct (Settings → Pages → Deploy from branch `main` / `/(root)`) bez
Actions, pokud CI/CD není potřeba. Alfred rozhodne při implementaci.

## Souborová struktura projektu

```
/                           # GitHub Pages root (= web root)
├── index.html
├── 404.html
├── CNAME                   # "unagy.cz"
├── css/
│   ├── tokens.css          # CSS custom properties
│   └── style.css
├── img/
│   ├── qr-google-play.svg
│   ├── qr-app-store.svg
│   └── logo.svg
└── .github/
    └── workflows/
        └── deploy.yml
```

## QR kódy

- Generovány staticky (SVG nebo PNG) — žádná runtime QR knihovna.
- Obsah: Google Play URL + App Store URL pro aplikaci Unagy.
- Alternativa: odkaz na stažení přímo bez QR (fallback pro desktop).

## Redirect / odkaz na app.unagy.cz

- Přímý `<a href="https://app.unagy.cz">` odkaz na landing page.
- Volitelně meta refresh nebo JS redirect pokud bude URL `unagy.cz/app` → `app.unagy.cz`
  (rozhodnutí ve spec).

## Security headers

GitHub Pages nepodporuje vlastní HTTP hlavičky. Alternativy:
- `<meta http-equiv="Content-Security-Policy" ...>` v HTML `<head>` (omezené)
- Cloudflare proxy (pokud doména půjde přes CF) → Worker nebo Transform Rules pro CSP header
- Heimdall flaguje pokud CSP chybí; rozhodnutí o Cloudflare ve spec.

---

## §Scaffold

_(prázdná sekce — doplní role `architecture`/`feasibility` při první feature wave)_

## §Extraction Candidates

| Soubor / pattern | Typ | Kandidát na pravidlo | Stav |
|---|---|---|---|
| — | — | — | — |
