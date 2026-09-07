# unagy-web

Prezentační web appky **Unagy** (podpůrná aplikace pro lidi s poruchami příjmu potravy a jejich rodiny), pod záštitou psychoterapeutky **Terezie Nagy Štolbové**.

Vlastní WordPress theme (bez parent theme) ve složce [`theme/unagy/`](theme/unagy). Jednostránkový web s kotevní navigací, nastavitelný přes wp-admin bez zásahu do kódu.

## Nasazení na WEDOS

1. **Theme** — nahraj celou složku `theme/unagy/` do `wp-content/themes/unagy/` (přes FTP), nebo ji zabal do `unagy.zip` a nahraj přes _Vzhled → Šablony → Nahrát šablonu_ ve wp-adminu. Pak theme aktivuj.
2. **Kontaktní formulář** — nainstaluj a aktivuj plugin **Contact Form 7**. Vytvoř nový formulář s poli podle zadání (jméno je nepovinné, e-mail a zpráva povinné), a přidej GDPR souhlas:

   ```
   <p>Jméno a příjmení<br>
   [text your-name]</p>

   <p>Váš e-mail<br>
   [email* your-email]</p>

   <p>Telefon<br>
   [tel your-phone]</p>

   <p>Zpráva<br>
   [textarea* your-message]</p>

   <p>[acceptance acceptance-gdpr] Souhlasím se zpracováním výše uvedených údajů za účelem vyřízení mého dotazu. [/acceptance]</p>

   [submit "Odeslat zprávu"]
   ```

   Ulož formulář a zkopíruj jeho shortcode (např. `[contact-form-7 id="12" title="Kontakt"]`).

3. **Nastavení webu** — v adminu jdi do _Nastavení → Unagy web_ a vyplň:
   - shortcode kontaktního formuláře z kroku 2,
   - kontaktní e-mail, telefon, lokalitu,
   - termín nejbližšího semináře/webináře, jakmile budou známé,
   - odkaz na podcast, formulář pro testery appky a App Store / Google Play, jakmile budou existovat (do té doby se zobrazují placeholdery "Připravujeme").

   Žádná z těchto hodnot není v kódu — dají se kdykoliv změnit přes wp-admin.

4. **Textové odstavce sekcí** — při první aktivaci theme se v _Stránky_ automaticky založí 6 pomocných stránek `Text: …` (O mně, Semináře, Webináře, Aplikace, Podcast, Kontakt) předvyplněných zadaným textem. Terezie je může kdykoliv upravit v běžném WP editoru (Stránky → najít podle názvu → upravit → Aktualizovat) — editor tam povoluje jen odstavec a seznam, aby úpravou textu nešlo rozbít vzhled webu. Tyhle stránky nemají vlastní veřejnou URL (návštěvník je z nich přesměrován na homepage) — slouží jen jako zdroj textu pro příslušnou sekci. Nadpisy sekcí (H1/H2) zůstávají pevné v kódu, protože se na ně odkazuje navigace.

5. **Doména** — `unagy.cz` teď ještě ukazuje na starý GitHub Pages web (statická landing page s Luna animací, nasazená dřív). Až bude WP verze hotová a otestovaná, přepoj DNS `unagy.cz` na WEDOS hosting (mimo tento repo, přes správu domény) a GitHub Pages nasazení v repu nechej vypnuté/smazané.

## Design

- Barvy a fonty jsou v `:root` na začátku `theme/unagy/style.css` (terakotová `#d08763` jako akcentní barva, převzatá z appky Unagy; světlé pozadí — bez appkového dark módu).
- Fonty: Fraunces (nadpisy) + Manrope (text), načítané z Google Fonts.
- Bez maskota/animace appky (Luna) — pouze obsah zadaný pro tento web.
- QR kódy pro App Store / Google Play se generují automaticky z odkazů v nastavení (přes veřejné qrserver.com API), takže není potřeba je nikde ručně vyrábět.

## Vývoj

Žádný build krok — čisté PHP/CSS, žádné závislosti mimo WordPress a plugin Contact Form 7. Pro lokální náhled stačí libovolné lokální WP prostředí (např. Local, DDEV) s theme nahraným do `wp-content/themes/`.
