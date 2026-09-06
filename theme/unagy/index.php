<?php
/**
 * Záložní šablona vyžadovaná WordPressem.
 * Web je jednostránkový — skutečný obsah je ve front-page.php.
 */
get_header();
?>
<div class="container">
	<?php if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>
		<article>
			<h1><?php the_title(); ?></h1>
			<div><?php the_content(); ?></div>
		</article>
	<?php endwhile; endif; ?>
</div>
<?php
get_footer();
