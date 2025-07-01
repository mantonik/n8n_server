<?php
require_once __DIR__ . '/conf/config.php';
require_once __DIR__ . '/includes/functions.php';
require_once __DIR__ . '/includes/auth.php';

$auth_required_pages = ['home'];
$page = $_GET['page'] ?? 'home';
$pagePath = realpath(__DIR__ . '/pages/' . str_replace(['..', '\\'], '', $page) . '.php');
if (!$pagePath || strpos($pagePath, realpath(__DIR__ . '/pages/')) !== 0) {
    http_response_code(404);
    die('404 Page Not Found');
}

$template = 'template1';
$templateDir = __DIR__ . "/template/$template";
$templateLayout = "$templateDir/layout.php";

if (in_array($page, $auth_required_pages) && !is_logged_in()) {
    header("Location: /?page=login");
    exit();
}

include $templateLayout;