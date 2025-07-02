<?php
// ========================================
// template1_header.php - Template Header
// Version: 1.0.1
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Template header with navigation
// Location: template/template1/header.php
// ========================================

$config = $framework->getConfig();
?>
<header class="site-header">
    <div class="container">
        <div class="header-content">
            <h1 class="site-title">
                <a href="?"><?php echo htmlspecialchars($config['site_name'] ?? 'My Modular Site'); ?></a>
            </h1>
            
            <nav class="main-navigation">
                <ul>
                    <li><a href="?">Home</a></li>
                    <li><a href="?page=info">Info</a></li>
                    <li><a href="?page=about">About</a></li>
                </ul>
            </nav>
        </div>
    </div>
</header>