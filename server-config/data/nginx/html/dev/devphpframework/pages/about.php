<?php
// ========================================
// about.php - About Page Content
// Version: 1.0.0
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: About page content
// Location: pages/about.php
// ========================================
?>

<div class="about-page">
    <h1><?php echo isset($framework) ? $framework->getMetadata('title') : 'About Page'; ?></h1>
    
    <div class="content">
        <p>This is the about page demonstrating the PHP modular framework.</p>
        
        <h2>Framework Architecture</h2>
        <p>The framework uses a modular approach with the following components:</p>
        
        <ul>
            <li><strong>Router:</strong> Handles URL routing and page loading</li>
            <li><strong>Templates:</strong> Provides flexible theming system</li>
            <li><strong>Pages:</strong> Content management system</li>
            <li><strong>Metadata:</strong> SEO and page information management</li>
        </ul>
        
        <h2>Technical Details</h2>
        <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
        <p><strong>Server:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></p>
        <p><strong>Document Root:</strong> <?php echo $_SERVER['DOCUMENT_ROOT'] ?? 'Unknown'; ?></p>
    </div>
</div>