<?php
// ========================================
// meta.php - Bulletproof Central Metadata Configuration
// Version: 1.0.2
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Central metadata with complete error prevention
// Location: pages/meta.php
// ========================================

// Central metadata configuration for all pages
$pageMetadata = [
    'home' => [
        'title' => 'Home - My Modular Site',
        'description' => 'Welcome to the PHP modular framework homepage',
        'keywords' => 'php, framework, modular, home',
        'template' => 'template1'
    ],
    
    'info' => [
        'title' => 'Information Page',
        'description' => 'Learn about our modular PHP framework features and capabilities',
        'keywords' => 'php, framework, modular, information, features',
        'template' => 'template1'
    ],
    
    'about' => [
        'title' => 'About - My Modular Site',
        'description' => 'Learn about the PHP modular framework architecture and technical details',
        'keywords' => 'php, framework, about, architecture, technical',
        'template' => 'template1'
    ],
    
    'contact' => [
        'title' => 'Contact Us - My Modular Site',
        'description' => 'Get in touch with us through our contact form',
        'keywords' => 'contact, form, email, support',
        'template' => 'template1'
    ],
    
    'blog' => [
        'title' => 'Blog - My Modular Site',
        'description' => 'Read our latest blog posts and updates',
        'keywords' => 'blog, posts, news, updates',
        'template' => 'template1'
    ]
];

// Default metadata
$defaultMetadata = [
    'title' => 'Page - My Modular Site',
    'description' => 'A page on our modular PHP framework website',
    'keywords' => 'php, framework, modular',
    'template' => 'template1'
];

// Determine which page metadata to return
$requestedPageName = null;

// Check if $requestedPage variable exists and is valid
if (isset($requestedPage) && $requestedPage !== null && $requestedPage !== '') {
    $requestedPageName = basename($requestedPage);
}

// Get the metadata for the requested page
if ($requestedPageName !== null && array_key_exists($requestedPageName, $pageMetadata)) {
    return $pageMetadata[$requestedPageName];
} elseif ($requestedPageName !== null) {
    // Page not found in metadata, create default with custom title
    $customDefault = $defaultMetadata;
    $customDefault['title'] = ucfirst($requestedPageName) . ' - My Modular Site';
    return $customDefault;
} else {
    // No page requested or invalid page, return default
    return $defaultMetadata;
}
?>