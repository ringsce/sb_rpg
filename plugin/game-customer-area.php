<?php
/*
Plugin Name: Game Customer Area
Description: A customer area for logged-in users to download the game.
Version: 1.1
Author: Kreatyve Designs <pdvicente@gleentech.com>
*/

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

// Add a menu for the game file upload in the WordPress admin
function game_customer_area_menu() {
    add_menu_page(
        'Game Customer Area',
        'Game Area',
        'manage_options',
        'game-customer-area',
        'game_customer_area_admin_page',
        'dashicons-download',
        20
    );
}
add_action('admin_menu', 'game_customer_area_menu');

// Admin page to upload the game file
function game_customer_area_admin_page() {
    if (!current_user_can('manage_options')) {
        return;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['game_file'])) {
        $file = $_FILES['game_file'];

        if ($file['error'] === UPLOAD_ERR_OK) {
            $upload_dir = wp_upload_dir();
            $target_path = $upload_dir['basedir'] . '/game-files/' . basename($file['name']);
            wp_mkdir_p($upload_dir['basedir'] . '/game-files');

            if (move_uploaded_file($file['tmp_name'], $target_path)) {
                update_option('game_file_url', $upload_dir['baseurl'] . '/game-files/' . basename($file['name']));
                echo '<div class="notice notice-success"><p>Game file uploaded successfully!</p></div>';
            } else {
                echo '<div class="notice notice-error"><p>Failed to upload the file.</p></div>';
            }
        } else {
            echo '<div class="notice notice-error"><p>Error uploading file.</p></div>';
        }
    }

    $game_file_url = get_option('game_file_url', '');
    ?>
    <div class="wrap">
        <h1>Game Customer Area</h1>
        <form method="POST" enctype="multipart/form-data">
            <table class="form-table">
                <tr>
                    <th><label for="game_file">Upload Game File</label></th>
                    <td><input type="file" name="game_file" id="game_file" required></td>
                </tr>
            </table>
            <?php submit_button('Upload Game'); ?>
        </form>

        <?php if ($game_file_url): ?>
            <h2>Current Game File</h2>
            <p><a href="<?php echo esc_url($game_file_url); ?>" target="_blank">Download Current Game</a></p>
        <?php endif; ?>
    </div>
    <?php
}

// Shortcode for customer area
function game_customer_area_shortcode() {
    if (!is_user_logged_in()) {
        return '<p>You must be logged in to access the customer area. <a href="' . wp_login_url() . '">Login here</a>.</p>';
    }

    $game_file_url = get_option('game_file_url', '');
    if ($game_file_url) {
        return '<p>Thank you for being a valued customer! <a href="' . esc_url($game_file_url) . '" target="_blank" class="game-download-button">Download Game</a></p>';
    } else {
        return '<p>The game is currently unavailable. Please check back later.</p>';
    }
}
add_shortcode('game_customer_area', 'game_customer_area_shortcode');

// Enqueue custom styles
function game_customer_area_styles() {
    echo '<style>
        .game-download-button {
            display: inline-block;
            padding: 10px 20px;
            background-color: #0073aa;
            color: #fff;
            text-decoration: none;
            border-radius: 5px;
        }
        .game-download-button:hover {
            background-color: #005177;
        }
    </style>';
}
add_action('wp_head', 'game_customer_area_styles');

