<?php
// ========================================
// info.php - Information Page (Fixed)
// Version: 1.0.1
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Information page with proper framework integration
// Location: pages/info.php
// ========================================
?>

<div class="info-page">
    <h1><?php echo isset($framework) ? $framework->getMetadata('title') : 'Information Page'; ?></h1>
    
    <div class="content">
        <p>This is the info page content. This page demonstrates the modular framework in action.</p>
        
        <h2>Framework Features</h2>
        <ul>
            <li>✅ Modular page routing</li>
            <li>✅ Template system with multiple themes</li>
            <li>✅ Centralized metadata management</li>
            <li>⚙️ Database abstraction layer (coming soon)</li>
            <li>⚙️ Authentication system (coming soon)</li>
        </ul>
        
        <h2>Current Page Information</h2>
        <?php if (isset($framework)): ?>
            <p><strong>Page Title:</strong> <?php echo htmlspecialchars($framework->getMetadata('title')); ?></p>
            <p><strong>Description:</strong> <?php echo htmlspecialchars($framework->getMetadata('description')); ?></p>
            <p><strong>Keywords:</strong> <?php echo htmlspecialchars($framework->getMetadata('keywords')); ?></p>
            <p><strong>Template:</strong> <?php echo htmlspecialchars($framework->getMetadata('template')); ?></p>
        <?php else: ?>
            <p><em>Framework information not available</em></p>
        <?php endif; ?>
        
        <h2>System Information</h2>
        <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
        <p><strong>Current Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
        <p><strong>Server:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></p>
    </div>
</div>