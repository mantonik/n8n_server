<?php
// ========================================
// meta.php - Central Metadata Configuration (Fixed)
// Version: 1.0.1
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Central metadata for all pages with proper null handling
// Location: pages/meta.php
// ========================================

// Central metadata configuration for all pages
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
    
    // Handle null or empty page name
    if (empty($pageName) || $pageName === null) {
        return $pageMetadata['default'];
    }
    
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

// Check if this file is being included with a specific page request
if (isset($requestedPage) && !empty($requestedPage)) {
    // Return metadata for the specific requested page
    return getPageMetadata($requestedPage);
} else {
    // Return default metadata if no page specified or page is null/empty
    return $pageMetadata['default'];
}
?>