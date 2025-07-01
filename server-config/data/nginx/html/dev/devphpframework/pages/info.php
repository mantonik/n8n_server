// ========================================
// pages/info.php - Sample Page
// ========================================

<div class="info-page">
    <h1><?php echo $framework->getMetadata('title'); ?></h1>
    
    <div class="content">
        <p>This is the info page content. This page demonstrates the modular framework in action.</p>
        
        <h2>Framework Features</h2>
        <ul>
            <li>Modular page routing</li>
            <li>Template system with multiple themes</li>
            <li>Database abstraction layer</li>
            <li>Authentication system</li>
            <li>Metadata injection</li>
        </ul>
        
        <?php if (AuthManager::isAuthenticated()): ?>
            <p>Welcome back, <?php echo AuthManager::getCurrentUser()['username']; ?>!</p>
        <?php else: ?>
            <p><a href="?page=login">Login</a> to access more features.</p>
        <?php endif; ?>
    </div>
</div>