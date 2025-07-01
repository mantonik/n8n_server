#!/bin/bash
# ========================================
# debug_nginx_404.sh - Nginx 404 Troubleshooting Script
# Version: 1.0.0
# Created: 2025-07-01
# Framework: PHP Modular Development Framework
# Purpose: Diagnose and fix 404 errors for devphpframework
# ========================================

echo "=========================================="
echo "Nginx 404 Troubleshooting Script"
echo "=========================================="

# Define variables
WEBROOT="/data/nginx/html/dev/devphpframework"
NGINX_USER="nginx"
DOMAIN="devphpframework.dmcloudarchitect.com"

echo "1. Checking document root directory..."
echo "Document root: $WEBROOT"

if [ -d "$WEBROOT" ]; then
    echo "✓ Document root exists"
    ls -la $WEBROOT
else
    echo "✗ Document root does not exist!"
    echo "Creating directory..."
    sudo mkdir -p $WEBROOT
fi

echo ""
echo "2. Checking index.php file..."
if [ -f "$WEBROOT/index.php" ]; then
    echo "✓ index.php exists"
    ls -la $WEBROOT/index.php
else
    echo "✗ index.php does not exist!"
    echo "You need to upload your index.php file to $WEBROOT"
fi

echo ""
echo "3. Checking file permissions..."
echo "Directory permissions:"
ls -ld $WEBROOT

echo ""
echo "Files in webroot:"
ls -la $WEBROOT/

echo ""
echo "4. Checking ownership..."
CURRENT_OWNER=$(stat -c '%U' $WEBROOT 2>/dev/null || echo "unknown")
echo "Current owner: $CURRENT_OWNER"

if [ "$CURRENT_OWNER" != "$NGINX_USER" ] && [ "$CURRENT_OWNER" != "www-data" ]; then
    echo "⚠ Warning: Directory not owned by nginx user"
    echo "Run these commands to fix ownership:"
    echo "sudo chown -R $NGINX_USER:$NGINX_USER $WEBROOT"
    echo "sudo chmod 755 $WEBROOT"
    echo "sudo chmod 644 $WEBROOT/*.php"
fi

echo ""
echo "5. Checking nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✓ Nginx configuration is valid"
else
    echo "✗ Nginx configuration has errors!"
fi

echo ""
echo "6. Checking if nginx is running..."
if pgrep nginx > /dev/null; then
    echo "✓ Nginx is running"
    ps aux | grep nginx | grep -v grep
else
    echo "✗ Nginx is not running!"
    echo "Start nginx with: sudo systemctl start nginx"
fi

echo ""
echo "7. Checking nginx error logs (last 10 lines)..."
if [ -f "/var/log/nginx/devphpframework_error.log" ]; then
    echo "Latest errors:"
    tail -10 /var/log/nginx/devphpframework_error.log
else
    echo "Error log not found, checking default error log:"
    tail -10 /var/log/nginx/error.log
fi

echo ""
echo "8. Checking nginx access logs (last 5 lines)..."
if [ -f "/var/log/nginx/devphpframework_access.log" ]; then
    echo "Latest access attempts:"
    tail -5 /var/log/nginx/devphpframework_access.log
else
    echo "Access log not found, checking default access log:"
    tail -5 /var/log/nginx/access.log
fi

echo ""
echo "9. Testing file accessibility as nginx user..."
if id "$NGINX_USER" >/dev/null 2>&1; then
    echo "Testing read access to index.php as $NGINX_USER:"
    sudo -u $NGINX_USER test -r "$WEBROOT/index.php" && echo "✓ Can read index.php" || echo "✗ Cannot read index.php"
    
    echo "Testing directory access as $NGINX_USER:"
    sudo -u $NGINX_USER test -x "$WEBROOT" && echo "✓ Can access directory" || echo "✗ Cannot access directory"
else
    echo "Nginx user '$NGINX_USER' not found, trying 'www-data':"
    NGINX_USER="www-data"
    sudo -u $NGINX_USER test -r "$WEBROOT/index.php" && echo "✓ Can read index.php" || echo "✗ Cannot read index.php"
fi

echo ""
echo "10. Checking parent directory permissions..."
echo "All parent directories need execute (x) permission:"
CURRENT_DIR="$WEBROOT"
while [ "$CURRENT_DIR" != "/" ]; do
    echo "$CURRENT_DIR: $(ls -ld "$CURRENT_DIR" | awk '{print $1, $3, $4}')"
    CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

echo ""
echo "11. Recommended fixes:"
echo "=========================================="
echo "If you're getting 404 errors, try these commands:"
echo ""
echo "# Fix ownership and permissions:"
echo "sudo chown -R $NGINX_USER:$NGINX_USER $WEBROOT"
echo "sudo find $WEBROOT -type d -exec chmod 755 {} \;"
echo "sudo find $WEBROOT -type f -exec chmod 644 {} \;"
echo ""
echo "# Ensure parent directories are accessible:"
echo "sudo chmod +x /data"
echo "sudo chmod +x /data/nginx"
echo "sudo chmod +x /data/nginx/html"
echo "sudo chmod +x /data/nginx/html/dev"
echo ""
echo "# Reload nginx configuration:"
echo "sudo nginx -s reload"
echo ""
echo "# Check if PHP-FPM is running:"
echo "sudo systemctl status php-fpm"
echo ""
echo "# Test the website:"
echo "curl -I http://$DOMAIN/"
echo "curl -v http://$DOMAIN/index.php"

echo ""
echo "=========================================="
echo "Troubleshooting complete!"
echo "=========================================="