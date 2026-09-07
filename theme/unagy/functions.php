<?php
/**
 * Funkce šablony Unagy.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'UNAGY_VERSION', '1.0.0' );

require_once get_template_directory() . '/inc/theme-options.php';
require_once get_template_directory() . '/inc/editable-sections.php';

function unagy_setup() {
	add_theme_support( 'title-tag' );
	add_theme_support( 'html5', array( 'search-form', 'comment-form', 'comment-list', 'gallery', 'caption' ) );
	add_theme_support( 'editor-styles' );
	add_editor_style( 'editor-style.css' );
}
add_action( 'after_setup_theme', 'unagy_setup' );

function unagy_enqueue_assets() {
	wp_enqueue_style(
		'unagy-fonts',
		'https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,600;0,9..144,700;1,9..144,400&family=Manrope:wght@400;500;600;700;800&display=swap',
		array(),
		null
	);
	wp_enqueue_style( 'unagy-style', get_stylesheet_uri(), array( 'unagy-fonts' ), UNAGY_VERSION );
}
add_action( 'wp_enqueue_scripts', 'unagy_enqueue_assets' );

// Drobný úklid <head> — bez emoji scriptu a verze WP ve zdrojovém kódu.
remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
remove_action( 'wp_print_styles', 'print_emoji_styles' );
remove_action( 'wp_head', 'wp_generator' );

/**
 * URL na QR kód s daným cílovým odkazem (App Store / Google Play).
 * Generuje se přes veřejné qrserver.com API, bez vlastní závislosti.
 */
function unagy_qr_code_url( $target_url ) {
	return 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&margin=8&data=' . rawurlencode( $target_url );
}
