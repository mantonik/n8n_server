#!/bin/bash

# Setup directories for Website Health Monitor
echo "📁 Setting up directories for Website Health Monitor..."

# Create main application directory structure
sudo mkdir -p /data/wwwapp/htdocs
sudo mkdir -p /data/wwwapp/logs/nginx
sudo mkdir -p /data/wwwapp/logs/supervisor
sudo mkdir -p /data/wwwapp/docker-configs

echo "✅ Created directories:"
echo "   • /data/wwwapp/htdocs - Application files"
echo "   • /data/wwwapp/logs/nginx - Nginx logs"
echo "   • /data/wwwapp/logs/supervisor - Supervisor logs"
echo "   • /data/wwwapp/docker-configs - Docker configuration files"

# Set proper permissions
sudo chown -R $USER:$USER /data/wwwapp/
sudo chmod -R 755 /data/wwwapp/

echo "✅ Set permissions for user: $USER"

# Create a simple index.php for testing
cat > /data/wwwapp/htdocs/index.php << 'EOF'
<?php
// Test page - replace with your health monitor application
phpinfo();

// Test database connection
try {
    $host = $_ENV['DB_HOST'] ?? getenv('DB_HOST') ?? '10.20.2.34';
    $dbname = $_ENV['DB_NAME'] ?? getenv('DB_NAME') ?? 'n8n_url_healthcheck';
    $username = $_ENV['DB_USER'] ?? getenv('DB_USER') ?? 'n8nheathcheckusr';
    $password = $_ENV['DB_PASS'] ?? getenv('DB_PASS') ?? 'Edcvfr5687#9ikjJhsg';
    
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    echo "<h2 style='color: green;'>✅ Database connection successful!</h2>";
    echo "<p>Connected to: $host/$dbname</p>";
} catch(PDOException $e) {
    echo "<h2 style='color: red;'>❌ Database connection failed!</h2>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
}
?>
EOF

echo "✅ Created test index.php file"

# Show directory structure
echo ""
echo "📋 Directory structure created:"
tree /data/wwwapp/ 2>/dev/null || find /data/wwwapp/ -type d

echo ""
echo "🚀 Next steps:"
echo "1. Copy your PHP health monitor files to: /data/wwwapp/htdocs/"
echo "2. Build and run the Docker container"
echo "3. Access the application at: http://your-server:8001"

echo ""
echo "📝 Useful commands:"
echo "   • Copy files: cp -r /path/to/your/php/files/* /data/wwwapp/htdocs/"
echo "   • Check permissions: ls -la /data/wwwapp/htdocs/"
echo "   • View logs: tail -f /data/wwwapp/logs/nginx/access.log"