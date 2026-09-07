<?php
/**
 * Textové odstavce jednotlivých sekcí jako obyčejné WP stránky,
 * editovatelné přes klasický/blokový editor (Stránky → Text: …).
 *
 * Nadpisy sekcí a strukturovaná data (termíny, ceny, kontakty, odkazy)
 * zůstávají v Nastavení → Unagy web (theme-options.php) — jde jen
 * o volný text pod nadpisy.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

function unagy_editable_sections() {
	return array(
		'text-o-mne'    => array(
			'title'   => 'Text: O mně (úvod)',
			'content' => "<!-- wp:paragraph -->\n<p>Jsem psychoterapeutka, autorka a lektorka. Specializuji se na psychoterapii <strong>poruch příjmu potravy</strong>. Pomáhám porozumět tomu, co se za nemocí skrývá, a hledat cestu ven – k větší svobodě, vztahu k sobě i vlastnímu tělu.</p>\n<!-- /wp:paragraph -->\n\n<!-- wp:paragraph -->\n<p>Anorexie, bulimie, přejídání i další podoby poruch příjmu potravy mohou postupně ovládnout celý život. V terapii hledáme, <strong>co nemoc říká, proč přišla a co potřebuje člověk změnit, aby ji už nepotřeboval.</strong></p>\n<!-- /wp:paragraph -->",
		),
		'text-seminare' => array(
			'title'   => 'Text: Odborné semináře (úvod)',
			'content' => "<!-- wp:paragraph -->\n<p>Pravidelně nabízí semináře zaměřené na praxi v oblasti poruch příjmu potravy určené pro psychology, terapeuty a zdravotníky.</p>\n<!-- /wp:paragraph -->",
		),
		'text-webinare' => array(
			'title'   => 'Text: Webináře pro veřejnost (úvod)',
			'content' => "<!-- wp:paragraph -->\n<p>Edukativní online setkání pro každého, kdo se chce dozvědět více o PPP, prevenci nebo o tom, jak podpořit někoho blízkého.</p>\n<!-- /wp:paragraph -->",
		),
		'text-aplikace' => array(
			'title'   => 'Text: Aplikace Unagy',
			'content' => "<!-- wp:paragraph -->\n<p>Vyvíjíme podpůrnou aplikaci Unagy – digitálního průvodce pro lidi procházející poruchou příjmu potravy a jejich rodiny. Pomáhá zvládat náročné momenty v každodenním životě.</p>\n<!-- /wp:paragraph -->\n\n<!-- wp:paragraph -->\n<p>Chcete se zapojit do testování a pomoci nám aplikaci vylepšit?</p>\n<!-- /wp:paragraph -->",
		),
		'text-podcast'  => array(
			'title'   => 'Text: Podcast',
			'content' => "<!-- wp:paragraph -->\n<p>Otevřené rozhovory nejen o poruchách příjmu potravy. Podcast Terezie Nagy Štolbové a spisovatelky Petry Dvořákové přináší osobní příběhy, odborný pohled i rozhovory se zajímavými hosty.</p>\n<!-- /wp:paragraph -->",
		),
		'text-kontakt'  => array(
			'title'   => 'Text: Napište mi (úvod)',
			'content' => "<!-- wp:paragraph -->\n<p>Máte dotaz, zájem o terapii nebo konzultaci? Využijte kontaktní formulář níže.</p>\n<!-- /wp:paragraph -->",
		),
	);
}

/**
 * Jednorázově založí stránky se sekcemi, pokud ještě neexistují.
 * Bezpečné volat opakovaně — nic nepřepisuje, jen doplní chybějící.
 */
function unagy_seed_editable_sections() {
	foreach ( unagy_editable_sections() as $slug => $section ) {
		if ( get_page_by_path( $slug, OBJECT, 'page' ) ) {
			continue;
		}
		wp_insert_post(
			array(
				'post_title'   => $section['title'],
				'post_name'    => $slug,
				'post_content' => $section['content'],
				'post_status'  => 'publish',
				'post_type'    => 'page',
				'post_author'  => get_current_user_id() ?: 1,
			)
		);
	}
}

function unagy_maybe_seed_editable_sections() {
	if ( get_option( 'unagy_sections_seeded_v1' ) ) {
		return;
	}
	unagy_seed_editable_sections();
	update_option( 'unagy_sections_seeded_v1', 1 );
}
add_action( 'after_switch_theme', 'unagy_maybe_seed_editable_sections' );
add_action( 'admin_init', 'unagy_maybe_seed_editable_sections' );

/**
 * Vykreslený obsah dané sekce (přes standardní filtr the_content),
 * nebo prázdný řetězec, pokud stránka neexistuje/není publikovaná.
 */
function unagy_section_content( $slug ) {
	$page = get_page_by_path( $slug, OBJECT, 'page' );
	if ( ! $page || 'publish' !== $page->post_status ) {
		return '';
	}
	return apply_filters( 'the_content', $page->post_content );
}

/**
 * V editoru těchto sekcí povolit jen odstavec a seznam — ať si Terezie
 * upraví text, ale nerozbije jím rozvržení jednostránkového webu.
 */
function unagy_restrict_section_blocks( $allowed_blocks, $context ) {
	if ( empty( $context->post ) || 'page' !== $context->post->post_type ) {
		return $allowed_blocks;
	}
	if ( ! array_key_exists( $context->post->post_name, unagy_editable_sections() ) ) {
		return $allowed_blocks;
	}
	return array( 'core/paragraph', 'core/list', 'core/list-item' );
}
add_filter( 'allowed_block_types_all', 'unagy_restrict_section_blocks', 10, 2 );

/**
 * Tyhle pomocné stránky nemají mít vlastní veřejné URL (obsahují jen
 * useknutý odstavec bez zbytku designu) — návštěvníka pošleme na homepage.
 */
function unagy_redirect_section_pages() {
	if ( is_page() && array_key_exists( get_post_field( 'post_name' ), unagy_editable_sections() ) ) {
		wp_safe_redirect( home_url( '/' ), 301 );
		exit;
	}
}
add_action( 'template_redirect', 'unagy_redirect_section_pages' );
