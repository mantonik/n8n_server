<?php
// ========================================
// home.php - Home Page Content
// Version: 1.0.0
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Default home page content
// Location: pages/home.php
// ========================================
?>

<div class="home-page">
    <h1>Welcome to My Modular Site</h1>
    
    <div class="content">
        <p>This is the home page of your PHP modular framework. The framework is working correctly!</p>
        
        <h2>Framework Features</h2>
        <ul>
            <li>✅ Modular page routing</li>
            <li>✅ Template system</li>
            <li>✅ Metadata injection</li>
            <li>⚙️ Database support (coming soon)</li>
            <li>⚙️ Authentication system (coming soon)</li>
        </ul>
        
        <h2>Available Pages</h2>
        <ul>
            <li><a href="?page=home">Home</a> (this page)</li>
            <li><a href="?page=info">Info Page</a></li>
            <li><a href="?page=about">About Page</a></li>
        </ul>
        
        <p><strong>Current time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
        <p><strong>Framework version:</strong> 1.0.3</p>
    </div>
</div>