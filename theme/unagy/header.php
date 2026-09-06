<?php
/**
 * Hlavička šablony Unagy.
 */
?><!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>

<a class="skip-link" href="#hlavni-obsah">Přeskočit na obsah</a>

<header class="site-header">
	<div class="container site-header__inner">
		<a class="site-logo" href="<?php echo esc_url( home_url( '/' ) ); ?>">Unagy</a>
		<nav class="site-nav" aria-label="Hlavní navigace">
			<a href="#o-mne">O mně</a>
			<a href="#seminare">Semináře</a>
			<a href="#webinare">Webináře</a>
			<a href="#aplikace">Aplikace</a>
			<a href="#podcast">Podcast</a>
			<a href="#kontakt">Kontakt</a>
		</nav>
	</div>
</header>

<main id="hlavni-obsah">
