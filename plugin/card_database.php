<?php
/**
 * Plugin Name: Grid Cards Display
 * Description: A plugin to display cards in a grid layout with pagination.
 * Version: 1.0
 * Author: Kreatyve Designs <pdvicente@gleentech.com>
 */

// Enqueue styles for the grid layout
function grid_cards_enqueue_styles() {
    wp_enqueue_style('grid-cards-style', plugin_dir_url(__FILE__) . 'style.css');
}
add_action('wp_enqueue_scripts', 'grid_cards_enqueue_styles');

// Shortcode to display the grid
function grid_cards_display($atts) {
    $atts = shortcode_atts(
        [
            'posts_per_page' => 30,
        ],
        $atts
    );

    $paged = (get_query_var('paged')) ? get_query_var('paged') : 1;

    $args = [
        'post_type' => 'post',
        'posts_per_page' => (int)$atts['posts_per_page'],
        'paged' => $paged,
    ];

    $query = new WP_Query($args);

    $output = '<div class="grid-cards">';

    if ($query->have_posts()) {
        while ($query->have_posts()) {
            $query->the_post();
            $output .= '<div class="card">';
            $output .= '<a href="' . get_permalink() . '">';
            if (has_post_thumbnail()) {
                $output .= get_the_post_thumbnail(get_the_ID(), 'medium');
            }
            $output .= '<h3>' . get_the_title() . '</h3>';
            $output .= '</a>';
            $output .= '</div>';
        }
    } else {
        $output .= '<p>No posts found.</p>';
    }

    $output .= '</div>';

    // Pagination
    $output .= '<div class="pagination">';
    $output .= paginate_links([
        'total' => $query->max_num_pages,
        'current' => $paged,
    ]);
    $output .= '</div>';

    wp_reset_postdata();

    return $output;
}
add_shortcode('grid_cards', 'grid_cards_display');

// Create a default stylesheet for the grid layout
function grid_cards_create_stylesheet() {
    $css = "
    .grid-cards {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
        gap: 20px;
    }
    .card {
        border: 1px solid #ddd;
        border-radius: 5px;
        padding: 10px;
        text-align: center;
        transition: transform 0.2s;
    }
    .card:hover {
        transform: scale(1.05);
    }
    .card img {
        max-width: 100%;
        height: auto;
        border-bottom: 1px solid #ddd;
        margin-bottom: 10px;
    }
    .pagination {
        text-align: center;
        margin-top: 20px;
    }
    .pagination a {
        margin: 0 5px;
        text-decoration: none;
        padding: 5px 10px;
        border: 1px solid #ddd;
        border-radius: 3px;
    }
    .pagination .current {
        background-color: #0073aa;
        color: #fff;
        border-color: #0073aa;
    }
    ";

    file_put_contents(plugin_dir_path(__FILE__) . 'style.css', $css);
}
register_activation_hook(__FILE__, 'grid_cards_create_stylesheet');
