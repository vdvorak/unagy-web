<?php
/**
 * Nastavení webu upravitelná přes wp-admin (Nastavení → Unagy web),
 * bez zásahu do kódu: termíny seminářů/webinářů, kontakt a odkazy.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'UNAGY_OPTION_KEY', 'unagy_options' );

function unagy_get_option( $key, $default = '' ) {
	$options = get_option( UNAGY_OPTION_KEY, array() );
	return ! empty( $options[ $key ] ) ? $options[ $key ] : $default;
}

function unagy_options_fields() {
	return array(
		'seminar' => array(
			'title'  => 'Nejbližší odborný seminář',
			'fields' => array(
				'seminar_name'     => array( 'label' => 'Název semináře', 'type' => 'text' ),
				'seminar_datetime' => array( 'label' => 'Datum a čas', 'type' => 'text' ),
				'seminar_place'    => array( 'label' => 'Místo konání', 'type' => 'text' ),
				'seminar_price'    => array( 'label' => 'Cena', 'type' => 'text' ),
				'seminar_email'    => array( 'label' => 'E-mail pro přihlášení (prázdné = použije se kontaktní e-mail níže)', 'type' => 'email' ),
			),
		),
		'webinar' => array(
			'title'  => 'Nejbližší webinář pro veřejnost',
			'fields' => array(
				'webinar_topic'      => array( 'label' => 'Téma webináře', 'type' => 'text' ),
				'webinar_datetime'   => array( 'label' => 'Datum a čas', 'type' => 'text' ),
				'webinar_price'      => array( 'label' => 'Cena (nebo „zdarma“)', 'type' => 'text' ),
				'webinar_signup_url' => array( 'label' => 'Odkaz na přihlášení / registrační formulář', 'type' => 'url' ),
			),
		),
		'app' => array(
			'title'  => 'Aplikace Unagy',
			'fields' => array(
				'app_testers_url' => array( 'label' => 'Odkaz na formulář pro testery', 'type' => 'url' ),
				'app_store_url'   => array( 'label' => 'Odkaz na App Store (prázdné = zobrazí se „Připravujeme“)', 'type' => 'url' ),
				'google_play_url' => array( 'label' => 'Odkaz na Google Play (prázdné = zobrazí se „Připravujeme“)', 'type' => 'url' ),
			),
		),
		'podcast' => array(
			'title'  => 'Podcast',
			'fields' => array(
				'podcast_url' => array( 'label' => 'Odkaz na podcast', 'type' => 'url' ),
			),
		),
		'contact' => array(
			'title'  => 'Kontakt',
			'fields' => array(
				'contact_email'    => array( 'label' => 'E-mail', 'type' => 'email' ),
				'contact_phone'    => array( 'label' => 'Telefon', 'type' => 'text' ),
				'contact_location' => array( 'label' => 'Lokalita', 'type' => 'text' ),
				'cf7_shortcode'    => array( 'label' => 'Shortcode kontaktního formuláře (Contact Form 7), např. [contact-form-7 id="12" title="Kontakt"]', 'type' => 'text' ),
			),
		),
	);
}

function unagy_register_settings() {
	register_setting( 'unagy_options_group', UNAGY_OPTION_KEY, 'unagy_sanitize_options' );

	foreach ( unagy_options_fields() as $group_key => $group ) {
		add_settings_section( 'unagy_' . $group_key, $group['title'], '__return_false', 'unagy-options' );

		foreach ( $group['fields'] as $key => $field ) {
			add_settings_field(
				$key,
				$field['label'],
				'unagy_render_field',
				'unagy-options',
				'unagy_' . $group_key,
				array(
					'key'  => $key,
					'type' => $field['type'],
				)
			);
		}
	}
}
add_action( 'admin_init', 'unagy_register_settings' );

function unagy_render_field( $args ) {
	printf(
		'<input type="%1$s" name="%2$s[%3$s]" value="%4$s" class="regular-text" />',
		esc_attr( $args['type'] ),
		esc_attr( UNAGY_OPTION_KEY ),
		esc_attr( $args['key'] ),
		esc_attr( unagy_get_option( $args['key'] ) )
	);
}

function unagy_sanitize_options( $input ) {
	$sanitized    = array();
	$url_fields   = array( 'webinar_signup_url', 'app_testers_url', 'app_store_url', 'google_play_url', 'podcast_url' );
	$email_fields = array( 'seminar_email', 'contact_email' );

	foreach ( unagy_options_fields() as $group ) {
		foreach ( $group['fields'] as $key => $field ) {
			$raw = isset( $input[ $key ] ) ? trim( $input[ $key ] ) : '';

			if ( in_array( $key, $url_fields, true ) ) {
				$sanitized[ $key ] = esc_url_raw( $raw );
			} elseif ( in_array( $key, $email_fields, true ) ) {
				$sanitized[ $key ] = sanitize_email( $raw );
			} else {
				$sanitized[ $key ] = sanitize_text_field( $raw );
			}
		}
	}

	return $sanitized;
}

function unagy_add_options_page() {
	add_options_page(
		'Unagy — nastavení webu',
		'Unagy web',
		'manage_options',
		'unagy-options',
		'unagy_render_options_page'
	);
}
add_action( 'admin_menu', 'unagy_add_options_page' );

function unagy_render_options_page() {
	if ( ! current_user_can( 'manage_options' ) ) {
		return;
	}
	?>
	<div class="wrap">
		<h1>Unagy — nastavení webu</h1>
		<p>Tady upravíš termíny seminářů/webinářů, odkazy a kontaktní údaje bez zásahu do kódu.</p>
		<form action="options.php" method="post">
			<?php
			settings_fields( 'unagy_options_group' );
			do_settings_sections( 'unagy-options' );
			submit_button( 'Uložit nastavení' );
			?>
		</form>
	</div>
	<?php
}
