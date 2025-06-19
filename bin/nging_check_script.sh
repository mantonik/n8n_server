#!/bin/bash
# Nginx setup script for URLCheck dashboard

echo "🔧 Setting up Nginx for URLCheck Dashboard"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Backup current nginx.conf
echo "📁 Backing up current nginx.conf..."
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# Check if PHP-FPM is installed
echo "🔍 Checking PHP-FPM..."
if ! command -v php-fpm &> /dev/null; then
    echo "⚠️  PHP-FPM not found. Installing..."
    
    # Detect OS and install PHP-FPM
    if [ -f /etc/redhat-release ]; then
        # RHEL/CentOS/Rocky
        yum install -y php php-fpm php-mysql php-json php-mbstring php-xml
        systemctl enable php-fpm
    elif [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        apt update
        apt install -y php php-fpm php-mysql php-json php-mbstring php-xml
        systemctl enable php*-fpm
    else
        echo "❌ Unsupported OS. Please install PHP-FPM manually."
        exit 1
    fi
fi

# Find PHP-FPM socket path
echo "🔍 Finding PHP-FPM socket..."
PHP_SOCKET=""
for socket in /var/run/php/php*-fpm.sock /run/php-fpm/www.sock /var/run/php-fpm/php-fpm.sock; do
    if [ -S "$socket" ]; then
        PHP_SOCKET="$socket"
        break
    fi
done

if [ -z "$PHP_SOCKET" ]; then
    echo "❌ PHP-FPM socket not found. Please check PHP-FPM installation."
    echo "Common locations:"
    echo "  - /var/run/php/php8.1-fpm.sock (Ubuntu/Debian)"
    echo "  - /run/php-fpm/www.sock (RHEL/CentOS)"
    exit 1
fi

echo "✅ Found PHP-FPM socket: $PHP_SOCKET"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p /data/nginx/html/urlcheck
mkdir -p /data/nginx/letsencrypt

# Set proper permissions
chown -R nginx:nginx /data/nginx/html/urlcheck
chmod -R 755 /data/nginx/html/urlcheck

# Update nginx.conf with correct PHP socket
echo "⚙️  Updating nginx.conf..."
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /data/nginx/html;

        include /etc/nginx/default.d/*.conf;

        # URLCheck Dashboard
        location /urlcheck/ {
            alias /data/nginx/html/urlcheck/;
            index index.php index.html;
            
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-XSS-Protection "1; mode=block" always;
            
            location ~* \.css$ {
                add_header Content-Type "text/css" always;
                expires 1w;
                add_header Cache-Control "public, immutable" always;
                try_files $uri =404;
            }
            
            location ~* \.js$ {
                add_header Content-Type "application/javascript" always;
                expires 1w;
                add_header Cache-Control "public, immutable" always;
                try_files $uri =404;
            }
            
            location ~* \.(png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1M;
                add_header Cache-Control "public, immutable" always;
                try_files $uri =404;
            }
            
            location ~ \.php$ {
                try_files $uri =404;
                fastcgi_pass unix:PHP_SOCKET_PLACEHOLDER;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME $request_filename;
                include fastcgi_params;
                fastcgi_read_timeout 60s;
                fastcgi_hide_header X-Powered-By;
            }
            
            location ~ /\. {
                deny all;
                access_log off;
                log_not_found off;
            }
            
            location ~* \.(conf|config|ini|sql|bak|backup)$ {
                deny all;
                access_log off;
                log_not_found off;
            }
        }

        # N8N Application
        location / {
            proxy_pass http://127.0.0.1:5678;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port 443;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_connect_timeout 60s;
            proxy_read_timeout 60s;
            proxy_send_timeout 60s;
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
            proxy_buffering off;
            proxy_cache off;
        }

        location ^~ /.well-known/acme-challenge/ {
            default_type "text/plain";
            root /data/nginx/letsencrypt;
        }

        error_page 404 /404.html;
        location = /404.html {
            root /data/nginx/html;
            internal;
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /data/nginx/html;
            internal;
        }
        
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-XSS-Protection "1; mode=block" always;
        server_tokens off;
        
        gzip on;
        gzip_vary on;
        gzip_min_length 1024;
        gzip_types
            application/javascript
            application/json
            text/css
            text/javascript
            text/plain;
    }
}
EOF

# Replace PHP socket placeholder
sed -i "s|PHP_SOCKET_PLACEHOLDER|$PHP_SOCKET|g" /etc/nginx/nginx.conf

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # Start/restart services
    echo "🔄 Restarting services..."
    systemctl restart php-fpm
    systemctl restart nginx
    
    echo ""
    echo "🎉 Setup complete!"
    echo "📁 URLCheck files should be placed in: /data/nginx/html/urlcheck/"
    echo "🌐 Access your dashboard at: http://your-domain/urlcheck/"
    echo ""
    echo "📋 Next steps:"
    echo "1. Upload your PHP files to /data/nginx/html/urlcheck/"
    echo "2. Set proper file permissions: chown -R nginx:nginx /data/nginx/html/urlcheck/"
    echo "3. Test the dashboard: http://your-domain/urlcheck/login.php"
    echo ""
    echo "🔧 Configuration backup saved as: /etc/nginx/nginx.conf.backup.*"
    
else
    echo "❌ Nginx configuration test failed!"
    echo "🔄 Restoring backup..."
    cp /etc/nginx/nginx.conf.backup.* /etc/nginx/nginx.conf
    echo "💡 Please check the configuration manually"
    exit 1
fi