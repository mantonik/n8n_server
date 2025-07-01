// ========================================
// template/template1/header.php - Template Header
// ========================================

<header class="site-header">
    <div class="container">
        <div class="header-content">
            <h1 class="site-title">
                <a href="?"><?php echo $config['site_name']; ?></a>
            </h1>
            
            <nav class="main-navigation">
                <ul>
                    <li><a href="?">Home</a></li>
                    <li><a href="?page=info">Info</a></li>
                    <li><a href="?page=blog">Blog</a></li>
                    
                    <?php if (AuthManager::isAuthenticated()): ?>
                        <li><a href="?page=dashboard">Dashboard</a></li>
                        <li><a href="?page=logout">Logout</a></li>
                    <?php else: ?>
                        <li><a href="?page=login">Login</a></li>
                    <?php endif; ?>
                </ul>
            </nav>
        </div>
    </div>
</header>