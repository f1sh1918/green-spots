<?php
/**
 * Twenty Twenty-Five functions and definitions.
 *
 * @link https://developer.wordpress.org/themes/basics/theme-functions/
 *
 * @package WordPress
 * @subpackage Twenty_Twenty_Five
 * @since Twenty Twenty-Five 1.0
 */
add_filter(
    'jwt_auth_expire',
    function ( $expire, $issued_at ) {
        // 90 Tage * 24 Stunden * 60 Minuten * 60 Sekunden
        return $issued_at + (90 * 24 * 60 * 60);
    },
    10,
    2
);
add_filter(
    'jwt_auth_refresh_expire',
    function ( $expire, $issued_at ) {
        // 5 Jahre *365 Tage * 24 Stunden * 60 Minuten * 60 Sekunden
        return $issued_at + (5 * 365 * 24 * 60 * 60);
    },
    10,
    2
);

// Adjust ACF Fields to expose image urls

add_action( 'rest_api_init', function () {
    $fields = [ 'image', 'image2', 'image3' ];   // ← add as many as you want

    foreach ( $fields as $field ) {
        // full‑size URL
        register_rest_field( 'spot', $field . '_url', [
            'get_callback' => function ( $obj ) use ( $field ) {
                $id = get_post_meta( $obj['id'], $field, true );
                if ( ! is_numeric( $id ) ) return null;
                $src = wp_get_attachment_image_src( (int) $id, 'medium_large' );
                return $src[0] ?? null;
            },
            'schema' => [ 'type' => 'string', 'format' => 'uri' ],
        ] );

        // thumbnail URL (change 'thumbnail' to any size you like)
        register_rest_field( 'spot', $field . '_thumb', [
            'get_callback' => function ( $obj ) use ( $field ) {
                $id = get_post_meta( $obj['id'], $field, true );
                if ( ! is_numeric( $id ) ) return null;
                $src = wp_get_attachment_image_src( (int) $id, 'thumbnail' );
                return $src[0] ?? null;
            },
            'schema' => [ 'type' => 'string', 'format' => 'uri' ],
        ] );
    }

    register_rest_field( 'spot', 'author_name', [
        'get_callback' => function ( $obj ) {
            $author_id = $obj['author'];
            if ( ! $author_id ) return null;

            $author = get_userdata( $author_id );
            return $author ? $author->display_name : null;
        },
        'schema' => [ 'type' => 'string' ],
    ] );

    register_rest_field( 'user', 'roles', [
        'get_callback' => function ( $obj ) {
            $user = get_userdata( $obj['id'] );
            if ( ! $user ) return null;

            return $user->roles;
        },
        'schema' => [
            'type' => 'array',
            'items' => [ 'type' => 'string' ]
        ],
    ] );



} );

// Enable comments on the spot CPT and auto-approve comments from logged-in users.
add_action( 'init', function () {
    add_post_type_support( 'spot', 'comments' );
} );

add_filter( 'comments_open', function ( $open, $post_id ) {
    $post = get_post( $post_id );
    if ( $post && $post->post_type === 'spot' ) {
        return true;
    }
    return $open;
}, 10, 2 );

add_filter( 'pre_comment_approved', function ( $approved, $data ) {
    return is_user_logged_in() ? 1 : $approved;
}, 10, 2 );

// Adds theme support for post formats.
if ( ! function_exists( 'twentytwentyfive_post_format_setup' ) ) :
	/**
	 * Adds theme support for post formats.
	 *
	 * @since Twenty Twenty-Five 1.0
	 *
	 * @return void
	 */
	function twentytwentyfive_post_format_setup() {
		add_theme_support( 'post-formats', array( 'aside', 'audio', 'chat', 'gallery', 'image', 'link', 'quote', 'status', 'video' ) );
	}
endif;
add_action( 'after_setup_theme', 'twentytwentyfive_post_format_setup' );

// Enqueues editor-style.css in the editors.
if ( ! function_exists( 'twentytwentyfive_editor_style' ) ) :
	/**
	 * Enqueues editor-style.css in the editors.
	 *
	 * @since Twenty Twenty-Five 1.0
	 *
	 * @return void
	 */
	function twentytwentyfive_editor_style() {
		add_editor_style( 'assets/css/editor-style.css' );
	}
endif;
add_action( 'after_setup_theme', 'twentytwentyfive_editor_style' );

// Enqueues style.css on the front.
if ( ! function_exists( 'twentytwentyfive_enqueue_styles' ) ) :
	/**
	 * Enqueues style.css on the front.
	 *
	 * @since Twenty Twenty-Five 1.0
	 *
	 * @return void
	 */
	function twentytwentyfive_enqueue_styles() {
		wp_enqueue_style(
			'twentytwentyfive-style',
			get_parent_theme_file_uri( 'style.css' ),
			array(),
			wp_get_theme()->get( 'Version' )
		);
	}
endif;
add_action( 'wp_enqueue_scripts', 'twentytwentyfive_enqueue_styles' );

// Registers custom block styles.
if ( ! function_exists( 'twentytwentyfive_block_styles' ) ) :
	/**
	 * Registers custom block styles.
	 *
	 * @since Twenty Twenty-Five 1.0
	 *
	 * @return void
	 */
	function twentytwentyfive_block_styles() {
		register_block_style(
			'core/list',
			array(
				'name'         => 'checkmark-list',
				'label'        => __( 'Checkmark', 'twentytwentyfive' ),
				'inline_style' => '
				ul.is-style-checkmark-list {
					list-style-type: "\2713";
				}

				ul.is-style-checkmark-list li {
					padding-inline-start: 1ch;
				}',
			)
		);
	}
endif;
add_action( 'init', 'twentytwentyfive_block_styles' );

// Registers pattern categories.
if ( ! function_exists( 'twentytwentyfive_pattern_categories' ) ) :
	/**
	 * Registers pattern categories.
	 *
	 * @since Twenty Twenty-Five 1.0
	 *
	 * @return void
	 */
	function twentytwentyfive_pattern_categories() {

		register_block_pattern_category(
			'twentytwentyfive_page',
			array(
				'label'       => __( 'Pages', 'twentytwentyfive' ),
				'description' => __( 'A collection of full page layouts.', 'twentytwentyfive' ),
			)
		);

		register_block_pattern_category(
			'twentytwentyfive_post-format',
			array(
				'label'       => __( 'Post formats', 'twentytwentyfive' ),
				'description' => __( 'A collection of post format patterns.', 'twentytwentyfive' ),
			)
		);
	}
endif;
add_action( 'init', 'twentytwentyfive_pattern_categories' );

// Registers block binding sources.
if ( ! function_exists( 'twentytwentyfive_register_block_bindings' ) ) :
	/**
	 * Registers the post format block binding source.
	 *
	 * @since Twenty Twenty-Five 1.0
	 *
	 * @return void
	 */
	function twentytwentyfive_register_block_bindings() {
		register_block_bindings_source(
			'twentytwentyfive/format',
			array(
				'label'              => _x( 'Post format name', 'Label for the block binding placeholder in the editor', 'twentytwentyfive' ),
				'get_value_callback' => 'twentytwentyfive_format_binding',
			)
		);
	}
endif;
add_action( 'init', 'twentytwentyfive_register_block_bindings' );

// Registers block binding callback function for the post format name.
if ( ! function_exists( 'twentytwentyfive_format_binding' ) ) :
	/**
	 * Callback function for the post format name block binding source.
	 *
	 * @since Twenty Twenty-Five 1.0
	 *
	 * @return string|void Post format name, or nothing if the format is 'standard'.
	 */
	function twentytwentyfive_format_binding() {
		$post_format_slug = get_post_format();

		if ( $post_format_slug && 'standard' !== $post_format_slug ) {
			return get_post_format_string( $post_format_slug );
		}
	}
endif;
