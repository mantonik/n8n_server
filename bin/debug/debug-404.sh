#!/bin/bash

# Debug 404 Issues Script
# Version: 1.0 - Debug urlcheck-v1 and report 404 errors
# This script helps identify permission and configuration issues

echo "=== Nginx 404 Debug Script ==="
echo "Date: $(date)"
echo ""

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    echo "⚠ This script should be run with sudo for full access"
    echo "Run: sudo ./debug-404.sh"
    echo ""
fi

# 1. Check file existence and permissions
echo "=== 1. File System Check ==="
echo ""

check_path() {
    local path=$1
    local description=$2
    
    echo "Checking: $description"
    echo "Path: $path"
    
    if [ -e "$path" ]; then
        echo "✓ Exists"
        echo "  Permissions: $(ls -ld "$path" 2>/dev/null)"
        echo "  Owner: $(stat -c '%U:%G' "$path" 2>/dev/null)"
        
        if [ -d "$path" ]; then
            echo "  Directory contents:"
            ls -la "$path" | head -10
        fi
    else
        echo "✗ Does NOT exist"
    fi
    echo ""
}

# Check key paths
check_path "/data/nginx/html/urlcheck-v1" "URL Check directory"
check_path "/data/nginx/html/urlcheck-v1/login.php" "login.php file"
check_path "/data/nginx/html/urlcheck-v1/index.php" "index.php file"
check_path "/data/nginx/html/report" "Report directory" 
check_path "/data/nginx/html/report/report-list.php" "report-list.php file"

# 2. Check nginx configuration
echo "=== 2. Nginx Configuration Check ==="
echo ""

echo "Active nginx configurations:"
find /etc/nginx/conf.d -name "*.conf" -exec echo "File: {}" \; -exec grep -A 5 -B 2 "location.*urlcheck-v1\|location.*report" {} \; 2>/dev/null

echo ""
echo "Nginx configuration test:"
nginx -t 2>&1
echo ""

# 3. Check PHP-FPM
echo "=== 3. PHP-FPM Check ==="
echo ""

if systemctl is-active --quiet php-fpm; then
    echo "✓ PHP-FPM is running"
    echo "  Socket check:"
    if [ -S "/run/php-fpm/www.sock" ]; then
        echo "  ✓ Socket exists: /run/php-fpm/www.sock"
        echo "  Socket permissions: $(ls -l /run/php-fpm/www.sock)"
    else
        echo "  ✗ Socket missing: /run/php-fpm/www.sock"
        echo "  Available sockets:"
        find /run -name "*php*" -type s 2>/dev/null
    fi
else
    echo "✗ PHP-FPM is not running"
    echo "  Trying alternative names..."
    for service in php8.1-fpm php8.0-fpm php7.4-fpm; do
        if systemctl is-active --quiet $service; then
            echo "  ✓ $service is running"
        fi
    done
fi

echo ""

# 4. Test direct file access
echo "=== 4. Direct File Access Test ==="
echo ""

test_file_access() {
    local file=$1
    local description=$2
    
    echo "Testing: $description"
    
    if [ -f "$file" ]; then
        echo "✓ File exists: $file"
        
        # Test if nginx user can read it
        if sudo -u nginx test -r "$file" 2>/dev/null; then
            echo "✓ Nginx user can read the file"
        else
            echo "✗ Nginx user CANNOT read the file"
        fi
        
        # Show file content type
        file_type=$(file "$file" 2>/dev/null)
        echo "  File type: $file_type"
        
        # Show first few lines if it's a text file
        if [[ "$file_type" == *"PHP script"* ]] || [[ "$file_type" == *"text"* ]]; then
            echo "  First 3 lines:"
            head -3 "$file" 2>/dev/null | sed 's/^/    /'
        fi
    else
        echo "✗ File does not exist: $file"
    fi
    echo ""
}

test_file_access "/data/nginx/html/urlcheck-v1/login.php" "login.php"
test_file_access "/data/nginx/html/report/report-list.php" "report-list.php"

# 5. Test HTTP requests
echo "=== 5. HTTP Request Test ==="
echo ""

test_url() {
    local url=$1
    local description=$2
    
    echo "Testing: $description"
    echo "URL: $url"
    
    # Test with curl
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    echo "Response code: $response"
    
    if [ "$response" = "404" ]; then
        echo "✗ 404 Error - checking error logs..."
        echo "Recent nginx errors:"
        tail -5 /var/log/nginx/error.log 2>/dev/null | grep -i "404\|not found\|urlcheck\|report" || echo "No relevant errors found"
    elif [ "$response" = "200" ]; then
        echo "✓ Success!"
    else
        echo "⚠ Unexpected response: $response"
    fi
    echo ""
}

test_url "http://localhost/urlcheck-v1/login.php" "URL Check login.php"
test_url "http://localhost/report/report-list.php" "Report list.php"

# 6. Check nginx error logs
echo "=== 6. Recent Nginx Error Logs ==="
echo ""
echo "Last 10 error log entries:"
tail -10 /var/log/nginx/error.log 2>/dev/null || echo "Error log not accessible"

echo ""
echo "=== Debug Complete ==="
echo ""
echo "Common fixes:"
echo "1. Fix permissions: sudo chown -R nginx:nginx /data/nginx/html/"
echo "2. Fix directory permissions: sudo chmod -R 755 /data/nginx/html/"
echo "3. Fix file permissions: sudo chmod -R 644 /data/nginx/html/*/*"
echo "4. Reload nginx: sudo systemctl reload nginx"
echo "5. Check PHP-FPM socket path in nginx config"