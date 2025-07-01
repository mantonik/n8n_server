// ========================================
// template/template1/layout.php - Main Template Layout
// ========================================

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $framework->getMetadata('title'); ?> - <?php echo $config['site_name']; ?></title>
    <meta name="description" content="<?php echo $framework->getMetadata('description'); ?>">
    <meta name="keywords" content="<?php echo $framework->getMetadata('keywords'); ?>">
    
    <!-- Template CSS -->
    <link rel="stylesheet" href="<?php echo $framework->getTemplateUrl(); ?>/style.css">
    <!-- Global CSS -->
    <link rel="stylesheet" href="css/style.css">
    
    <!-- CSRF Token for forms -->
    <meta name="csrf-token" content="<?php echo generateCSRFToken(); ?>">
</head>
<body>
    <?php include $framework->getTemplatePath() . '/header.php'; ?>
    
    <main class="main-content">
        <?php echo $pageContent; ?>
    </main>
    
    <?php include $framework->getTemplatePath() . '/footer.php'; ?>
    
    <!-- Global JavaScript -->
    <script src="js/scripts.js"></script>
</body>
</html>