<?php
/**
 * Plugin Name: Green Spots CORS
 * Description: Allows CORS requests from the Green Spots web app on GitHub Pages.
 * Version: 1.0.0
 */

defined('ABSPATH') || exit;

add_action('init', function () {
    $allowed = 'https://f1sh1918.github.io';
    $origin  = $_SERVER['HTTP_ORIGIN'] ?? '';

    if ($origin === $allowed) {
        header("Access-Control-Allow-Origin: $allowed");
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Authorization, Content-Type');
        header('Access-Control-Allow-Credentials: true');
    }

    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        status_header(200);
        exit();
    }
});
