<?php
/*
Plugin Name: Game Customer Area with 2FA
Description: A customer area for logged-in users to download the game with two-factor authentication via email.
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

// Generate and send the OTP via email
function game_customer_area_send_otp($user_email) {
    $otp = wp_rand(100000, 999999);
    $subject = 'Your Two-Factor Authentication Code';
    $message = "Your verification code is: $otp";
    $headers = ['Content-Type: text/plain; charset=UTF-8'];

    if (wp_mail($user_email, $subject, $message, $headers)) {
        set_transient("game_customer_area_otp_$user_email", $otp, 300); // OTP valid for 5 minutes
    }
}

// Handle OTP verification
function game_customer_area_verify_otp($user_email, $entered_otp) {
    $stored_otp = get_transient("game_customer_area_otp_$user_email");
    if ($stored_otp && $stored_otp == $entered_otp) {
        delete_transient("game_customer_area_otp_$user_email");
        return true;
    }
    return false;
}

// Shortcode for customer area with 2FA
function game_customer_area_shortcode() {
    if (!is_user_logged_in()) {
        return '<p>You must be logged in to access the customer area. <a href="' . wp_login_url() . '">Login here</a>.</p>';
    }

    $user = wp_get_current_user();
    $game_file_url = get_option('game_file_url', '');

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['otp'])) {
        $otp = sanitize_text_field($_POST['otp']);
        if (game_customer_area_verify_otp($user->user_email, $otp)) {
            // OTP verified, grant access
            return $game_file_url
                ? '<p>Thank you for verifying your email! <a href="' . esc_url($game_file_url) . '" target="_blank" class="game-download-button">Download Game</a></p>'
                : '<p>The game is currently unavailable. Please check back later.</p>';
        } else {
            return '<p>Invalid OTP. Please try again.</p>' . game_customer_area_request_otp_form();
        }
    }

    // Send OTP if not verified
    if (!get_transient("game_customer_area_otp_$user->user_email")) {
        game_customer_area_send_otp($user->user_email);
        return '<p>A verification code has been sent to your email. Please enter it below:</p>' . game_customer_area_request_otp_form();
    }

    return '<p>Please enter the OTP sent to your email:</p>' . game_customer_area_request_otp_form();
}
add_shortcode('game_customer_area', 'game_customer_area_shortcode');

// Form to request OTP
function game_customer_area_request_otp_form() {
    return '<form method="POST">
                <input type="text" name="otp" placeholder="Enter OTP" required>
                <button type="submit">Verify</button>
            </form>';
}

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
