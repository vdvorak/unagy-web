# Defaults

Tech-agnostic defaulty pro rozhodnutí opakující se napříč features. Pokud spec
neřekne jinak, orchestrátor i workery je používají **bez dotazu**. Každý default
má explicitní výjimku — kdy neplatí (jinak sklouzne v implicitní pravidlo a
ztratí se možnost obhájit odchylku).

## Targety ve scope
- Default aktivní target pro novou feature: `web` (statické HTML/CSS)
- Ostatní targety (mobile/desktop/server): `—` dokud není explicitní rozhodnutí

## Content seeding
- Default: statický obsah přímo v HTML souborech
- Výjimky (odůvodnit ve spec): runtime-editovatelný obsah → zvaž CMS nebo
  oddělený repo; dynamický obsah → samostatné rozhodnutí o stacku

## Locale fallback
- Projekt je jednojazyčný (cs). Žádný locale fallback se neřeší.
- Pokud se přidá i18n → doplnit tento soubor před zahájením.

## Přístup (auth)
- Web je zcela veřejný. Žádná autentizace.
- Výjimka: pokud se přidá admin/CMS → vědomé rozhodnutí s bezpečnostním dopadem.

## Chybové chování
- Statický web: GitHub Pages zobrazí vlastní 404.html (pokud existuje).
- Default: vytvořit `404.html` při setupu stránky.

## Eskalace opakované ambiguity
- Stejná ambiguita ve 2+ features bez defaultu = BLOCKER pro spec-author —
  doplnit default sem PŘED pokračováním, ne improvizovat.
