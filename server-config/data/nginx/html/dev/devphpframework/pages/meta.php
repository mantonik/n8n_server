<?php
// ========================================
// meta.php - Central Metadata Configuration
// Version: 1.0.0
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Central metadata for all pages
// Location: pages/meta.php
// ========================================

// Central metadata configuration for all pages
// Usage: Each page's metadata is defined by its filename (without .php)

$pageMetadata = [
    // Home page metadata
    'home' => [
        'title' => 'Home - My Modular Site',
        'description' => 'Welcome to the PHP modular framework homepage',
        'keywords' => 'php, framework, modular, home',
        'template' => 'template1'
    ],
    
    // Info page metadata
    'info' => [
        'title' => 'Information Page',
        'description' => 'Learn about our modular PHP framework features and capabilities',
        'keywords' => 'php, framework, modular, information, features',
        'template' => 'template1'
    ],
    
    // About page metadata
    'about' => [
        'title' => 'About - My Modular Site',
        'description' => 'Learn about the PHP modular framework architecture and technical details',
        'keywords' => 'php, framework, about, architecture, technical',
        'template' => 'template1'
    ],
    
    // Contact page metadata (example for future use)
    'contact' => [
        'title' => 'Contact Us - My Modular Site',
        'description' => 'Get in touch with us through our contact form',
        'keywords' => 'contact, form, email, support',
        'template' => 'template1'
    ],
    
    // Blog page metadata (example for future use)
    'blog' => [
        'title' => 'Blog - My Modular Site',
        'description' => 'Read our latest blog posts and updates',
        'keywords' => 'blog, posts, news, updates',
        'template' => 'template1'
    ],
    
    // Default metadata for any page not explicitly defined
    'default' => [
        'title' => 'Page - My Modular Site',
        'description' => 'A page on our modular PHP framework website',
        'keywords' => 'php, framework, modular',
        'template' => 'template1'
    ]
];

// Function to get metadata for a specific page
function getPageMetadata($pageName) {
    global $pageMetadata;
    
    // Remove any path separators and get just the page name
    $pageName = basename($pageName);
    
    // Return specific page metadata or default
    if (isset($pageMetadata[$pageName])) {
        return $pageMetadata[$pageName];
    } else {
        // Use default metadata but update title with page name
        $defaultMeta = $pageMetadata['default'];
        $defaultMeta['title'] = ucfirst($pageName) . ' - My Modular Site';
        return $defaultMeta;
    }
}

// If this file is included directly, return metadata for the requested page
if (isset($requestedPage) && $requestedPage !== null) {
    return getPageMetadata($requestedPage);
}

// If no specific page requested, return default metadata
return $pageMetadata['default'] ?? [
    'title' => 'Page - My Modular Site',
    'description' => 'A page on our modular PHP framework website',
    'keywords' => 'php, framework, modular',
    'template' => 'template1'
];
?>