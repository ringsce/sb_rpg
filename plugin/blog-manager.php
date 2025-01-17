<?php
/*
Plugin Name: Blog Cards Frontpage
Description: Displays blog entries as cards on the front page with 30 posts per page.
Version: 1.0
Author: Kreatyve Designs <pdvicente@gleentech.com>
*/

function blog_cards_enqueue_styles() {
    wp_enqueue_style('blog-cards-style', plugin_dir_url(__FILE__) . 'style.css');
}
add_action('wp_enqueue_scripts', 'blog_cards_enqueue_styles');

function blog_cards_query($query) {
    if ($query->is_home() && $query->is_main_query()) {
        $query->set('posts_per_page', 30);
    }
}
add_action('pre_get_posts', 'blog_cards_query');

function blog_cards_template($content) {
    if (is_home() && is_main_query()) {
        ob_start();
        ?>
        <div class="blog-cards-grid">
            <?php if (have_posts()) : while (have_posts()) : the_post(); ?>
                <div class="blog-card">
                    <a href="<?php the_permalink(); ?>">
                        <?php if (has_post_thumbnail()) : ?>
                            <div class="blog-card-image">
                                <?php the_post_thumbnail('medium'); ?>
                            </div>
                        <?php endif; ?>
                        <div class="blog-card-content">
                            <h2><?php the_title(); ?></h2>
                            <p><?php echo wp_trim_words(get_the_excerpt(), 20, '...'); ?></p>
                        </div>
                    </a>
                </div>
            <?php endwhile; ?>
            </div>
            <div class="pagination">
                <?php the_posts_pagination(); ?>
            </div>
        <?php else : ?>
            <p>No posts found.</p>
        <?php endif;
        return ob_get_clean();
    }
    return $content;
}
add_filter('the_content', 'blog_cards_template');

function blog_cards_styles() {
    ?>
    <style>
        .blog-cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        .blog-card {
            border: 1px solid #ddd;
            border-radius: 8px;
            overflow: hidden;
            transition: transform 0.2s;
        }
        .blog-card:hover {
            transform: scale(1.05);
        }
        .blog-card-image img {
            width: 100%;
            height: auto;
        }
        .blog-card-content {
            padding: 15px;
        }
        .blog-card-content h2 {
            font-size: 1.2em;
            margin-bottom: 10px;
        }
        .blog-card-content p {
            color: #666;
        }
        .pagination {
            margin-top: 20px;
            text-align: center;
        }
    </style>
    <?php
}
add_action('wp_head', 'blog_cards_styles');
