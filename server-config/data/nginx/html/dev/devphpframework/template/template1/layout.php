<?php
// ========================================
// template1_layout.php - Template Layout
// Version: 1.0.1
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Main template layout with proper framework integration
// Location: template/template1/layout.php
// ========================================

$metadata = $framework->getMetadata();
$config = $framework->getConfig();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo htmlspecialchars($metadata['title'] ?? 'Page'); ?> - <?php echo htmlspecialchars($config['site_name'] ?? 'Site'); ?></title>
    <meta name="description" content="<?php echo htmlspecialchars($metadata['description'] ?? ''); ?>">
    <meta name="keywords" content="<?php echo htmlspecialchars($metadata['keywords'] ?? ''); ?>">
    
    <!-- Template CSS -->
    <link rel="stylesheet" href="<?php echo $framework->getTemplateUrl(); ?>/style.css">
    
    <style>
    /* Basic template styling */
    body {
        font-family: Arial, sans-serif;
        margin: 0;
        padding: 0;
        background-color: #f5f5f5;
    }
    .container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 20px;
    }
    .site-header {
        background: #007cba;
        color: white;
        padding: 1rem 0;
    }
    .site-title a {
        color: white;
        text-decoration: none;
    }
    .main-navigation ul {
        list-style: none;
        padding: 0;
        margin: 10px 0 0 0;
    }
    .main-navigation li {
        display: inline-block;
        margin-right: 20px;
    }
    .main-navigation a {
        color: white;
        text-decoration: none;
        padding: 5px 10px;
        border-radius: 3px;
    }
    .main-navigation a:hover {
        background: rgba(255,255,255,0.1);
    }
    .main-content {
        background: white;
        padding: 2rem 0;
        min-height: 400px;
    }
    .site-footer {
        background: #333;
        color: white;
        padding: 1rem 0;
        text-align: center;
        margin-top: 2rem;
    }
    </style>
</head>
<body>
    <?php include $framework->getTemplatePath() . '/header.php'; ?>
    
    <main class="main-content">
        <div class="container">
            <?php echo $pageContent; ?>
        </div>
    </main>
    
    <?php include $framework->getTemplatePath() . '/footer.php'; ?>
</body>
</html>