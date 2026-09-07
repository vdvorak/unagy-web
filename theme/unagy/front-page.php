<?php
/**
 * Úvodní (jediná) stránka webu — appka Unagy pod záštitou
 * psychoterapeutky Terezie Nagy Štolbové.
 */
get_header();

$seminar_name     = unagy_get_option( 'seminar_name' );
$seminar_datetime = unagy_get_option( 'seminar_datetime' );
$seminar_place    = unagy_get_option( 'seminar_place' );
$seminar_price    = unagy_get_option( 'seminar_price' );
$seminar_email    = unagy_get_option( 'seminar_email', unagy_get_option( 'contact_email' ) );

$webinar_topic      = unagy_get_option( 'webinar_topic' );
$webinar_datetime   = unagy_get_option( 'webinar_datetime' );
$webinar_price      = unagy_get_option( 'webinar_price' );
$webinar_signup_url = unagy_get_option( 'webinar_signup_url', '#kontakt' );

$app_testers_url = unagy_get_option( 'app_testers_url', '#kontakt' );
$app_store_url    = unagy_get_option( 'app_store_url' );
$google_play_url  = unagy_get_option( 'google_play_url' );

$podcast_url = unagy_get_option( 'podcast_url' );

$contact_email    = unagy_get_option( 'contact_email' );
$contact_phone    = unagy_get_option( 'contact_phone' );
$contact_location = unagy_get_option( 'contact_location', 'Brno / Online' );
$cf7_shortcode    = unagy_get_option( 'cf7_shortcode' );
?>

<section class="hero" id="o-mne">
	<div class="container">
		<h1>Terezie Nagy Štolbová</h1>
		<div class="section-text"><?php echo unagy_section_content( 'text-o-mne' ); ?></div>
	</div>
</section>

<section class="section" id="seminare">
	<div class="container">
		<h2>Odborné semináře</h2>
		<div class="section-text"><?php echo unagy_section_content( 'text-seminare' ); ?></div>

		<?php if ( $seminar_name ) : ?>
			<dl class="info-card">
				<div><dt>Název semináře</dt><dd><?php echo esc_html( $seminar_name ); ?></dd></div>
				<?php if ( $seminar_datetime ) : ?><div><dt>Datum a čas</dt><dd><?php echo esc_html( $seminar_datetime ); ?></dd></div><?php endif; ?>
				<?php if ( $seminar_place ) : ?><div><dt>Místo konání</dt><dd><?php echo esc_html( $seminar_place ); ?></dd></div><?php endif; ?>
				<?php if ( $seminar_price ) : ?><div><dt>Cena</dt><dd><?php echo esc_html( $seminar_price ); ?></dd></div><?php endif; ?>
			</dl>
			<?php if ( $seminar_email ) : ?>
				<p><em>Máte zájem o účast?</em> Přihlaste se e-mailem na <strong><a href="mailto:<?php echo esc_attr( $seminar_email ); ?>"><?php echo esc_html( $seminar_email ); ?></a></strong>.</p>
			<?php endif; ?>
		<?php else : ?>
			<p class="info-placeholder">Termín připravovaného semináře brzy upřesníme.</p>
		<?php endif; ?>
	</div>
</section>

<section class="section section--alt" id="webinare">
	<div class="container">
		<h2>Webináře pro veřejnost</h2>
		<div class="section-text"><?php echo unagy_section_content( 'text-webinare' ); ?></div>

		<?php if ( $webinar_topic ) : ?>
			<dl class="info-card">
				<div><dt>Téma webináře</dt><dd><?php echo esc_html( $webinar_topic ); ?></dd></div>
				<?php if ( $webinar_datetime ) : ?><div><dt>Datum a čas</dt><dd><?php echo esc_html( $webinar_datetime ); ?></dd></div><?php endif; ?>
				<?php if ( $webinar_price ) : ?><div><dt>Cena</dt><dd><?php echo esc_html( $webinar_price ); ?></dd></div><?php endif; ?>
			</dl>
		<?php else : ?>
			<p class="info-placeholder">Termín webináře brzy upřesníme.</p>
		<?php endif; ?>

		<a class="btn btn--primary" href="<?php echo esc_url( $webinar_signup_url ); ?>">Chci se přihlásit na webinář</a>
	</div>
</section>

<section class="section" id="aplikace">
	<div class="container">
		<h2>Aplikace Unagy</h2>
		<div class="section-text"><?php echo unagy_section_content( 'text-aplikace' ); ?></div>
		<a class="btn btn--primary" href="<?php echo esc_url( $app_testers_url ); ?>">Chci testovat aplikaci Unagy</a>

		<div class="store-badges">
			<div class="store-badge">
				<?php if ( $app_store_url ) : ?>
					<img src="<?php echo esc_url( unagy_qr_code_url( $app_store_url ) ); ?>" width="120" height="120" alt="QR kód ke stažení na App Store" loading="lazy">
					<a class="store-badge__link" href="<?php echo esc_url( $app_store_url ); ?>">Stáhnout na App Store</a>
				<?php else : ?>
					<span class="store-badge__soon">App Store<br>Připravujeme</span>
				<?php endif; ?>
			</div>
			<div class="store-badge">
				<?php if ( $google_play_url ) : ?>
					<img src="<?php echo esc_url( unagy_qr_code_url( $google_play_url ) ); ?>" width="120" height="120" alt="QR kód ke stažení na Google Play" loading="lazy">
					<a class="store-badge__link" href="<?php echo esc_url( $google_play_url ); ?>">Stáhnout na Google Play</a>
				<?php else : ?>
					<span class="store-badge__soon">Google Play<br>Připravujeme</span>
				<?php endif; ?>
			</div>
		</div>
	</div>
</section>

<section class="section section--alt" id="podcast">
	<div class="container">
		<h2>Podcast o poruchách příjmu potravy</h2>
		<div class="section-text"><?php echo unagy_section_content( 'text-podcast' ); ?></div>

		<?php if ( $podcast_url ) : ?>
			<a class="btn btn--primary" href="<?php echo esc_url( $podcast_url ); ?>">Poslechnout si podcast zde</a>
		<?php else : ?>
			<span class="btn btn--disabled">Podcast připravujeme</span>
		<?php endif; ?>
	</div>
</section>

<section class="section" id="kontakt">
	<div class="container">
		<h2>Napište mi</h2>
		<div class="section-text"><?php echo unagy_section_content( 'text-kontakt' ); ?></div>

		<?php if ( $cf7_shortcode ) : ?>
			<div class="contact-form"><?php echo do_shortcode( $cf7_shortcode ); ?></div>
		<?php else : ?>
			<p class="info-placeholder">
				Formulář se připravuje. Napište prosím zatím na
				<?php if ( $contact_email ) : ?>
					<a href="mailto:<?php echo esc_attr( $contact_email ); ?>"><?php echo esc_html( $contact_email ); ?></a>.
				<?php else : ?>
					e-mail uvedený níže.
				<?php endif; ?>
			</p>
		<?php endif; ?>

		<?php
		$contact_meta_parts = array();
		if ( $contact_email ) {
			$contact_meta_parts[] = '<strong>E-mail:</strong> <a href="mailto:' . esc_attr( $contact_email ) . '">' . esc_html( $contact_email ) . '</a>';
		}
		if ( $contact_phone ) {
			$contact_meta_parts[] = '<strong>Telefon:</strong> <a href="tel:' . esc_attr( preg_replace( '/\s+/', '', $contact_phone ) ) . '">' . esc_html( $contact_phone ) . '</a>';
		}
		if ( $contact_location ) {
			$contact_meta_parts[] = '<strong>Lokalita:</strong> ' . esc_html( $contact_location );
		}
		if ( $contact_meta_parts ) :
			?>
			<p class="contact-meta"><?php echo implode( ' | ', $contact_meta_parts ); ?></p>
		<?php endif; ?>
	</div>
</section>

<?php get_footer(); ?>
