<?php
// ========================================
// template1_footer.php - Template Footer
// Version: 1.0.1
// Created: 2025-07-02
// Framework: PHP Modular Development Framework
// Purpose: Template footer
// Location: template/template1/footer.php
// ========================================

$config = $framework->getConfig();
?>
<footer class="site-footer">
    <div class="container">
        <div class="footer-content">
            <p>&copy; <?php echo date('Y'); ?> <?php echo htmlspecialchars($config['site_name'] ?? 'My Modular Site'); ?>. All rights reserved.</p>
            <p>Powered by PHP Modular Framework v1.0.3</p>
        </div>
    </div>
</footer>