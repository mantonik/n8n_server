# Minimal Dockerfile for PHP + Nginx (Oracle Linux compatible)
FROM php:8.2-fpm-alpine

# Install system dependencies (minimal set)
RUN apk add --no-cache \
    # Build dependencies
    build-base \
    autoconf \
    # System utilities
    curl \
    wget \
    # Nginx
    nginx \
    # Supervisor for process management
    supervisor \
    # Image processing
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    # Database
    libzip-dev \
    libxml2-dev \
    oniguruma-dev \
    # Process management
    bash

# Configure and install essential PHP extensions only
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    gd \
    mysqli \
    pdo \
    pdo_mysql \
    zip \
    opcache \
    xml \
    mbstring \
    sockets

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create web directory
RUN mkdir -p /var/www/htdocs

# Set proper ownership and permissions
RUN addgroup -g 1000 -S nginx && \
    adduser -u 1000 -D -S -G nginx nginx && \
    chown -R nginx:nginx /var/www/htdocs && \
    chmod -R 755 /var/www/htdocs

# Create necessary directories
RUN mkdir -p \
    /var/log/nginx \
    /var/log/php \
    /var/log/supervisor \
    /run/nginx \
    /etc/supervisor.d \
    /var/cache/nginx \
    /var/tmp/nginx

# Configure PHP-FPM
RUN echo '[www]' > /usr/local/etc/php-fpm.d/www.conf && \
    echo 'user = nginx' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'group = nginx' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'listen = 127.0.0.1:9000' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'listen.owner = nginx' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'listen.group = nginx' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'listen.mode = 0660' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'pm = dynamic' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'pm.max_children = 50' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'pm.start_servers = 5' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'pm.min_spare_servers = 5' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'pm.max_spare_servers = 35' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'pm.max_requests = 500' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'ping.path = /ping' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'ping.response = pong' >> /usr/local/etc/php-fpm.d/www.conf && \
    echo 'catch_workers_output = yes' >> /usr/local/etc/php-fpm.d/www.conf

# Configure PHP
RUN echo 'memory_limit = 256M' > /usr/local/etc/php/conf.d/custom.ini && \
    echo 'max_execution_time = 300' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'max_input_time = 300' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'post_max_size = 50M' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'upload_max_filesize = 50M' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'max_file_uploads = 20' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'session.save_handler = files' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'session.save_path = "/tmp"' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'display_errors = Off' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'log_errors = On' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'error_log = /var/log/php/error.log' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'date.timezone = "UTC"' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'opcache.enable = 1' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'opcache.memory_consumption = 128' >> /usr/local/etc/php/conf.d/custom.ini && \
    echo 'expose_php = Off' >> /usr/local/etc/php/conf.d/custom.ini

# Configure Nginx
RUN echo 'user nginx;' > /etc/nginx/nginx.conf && \
    echo 'worker_processes auto;' >> /etc/nginx/nginx.conf && \
    echo 'error_log /var/log/nginx/error.log warn;' >> /etc/nginx/nginx.conf && \
    echo 'pid /run/nginx.pid;' >> /etc/nginx/nginx.conf && \
    echo 'events {' >> /etc/nginx/nginx.conf && \
    echo '    worker_connections 1024;' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf && \
    echo 'http {' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/mime.types;' >> /etc/nginx/nginx.conf && \
    echo '    default_type application/octet-stream;' >> /etc/nginx/nginx.conf && \
    echo '    sendfile on;' >> /etc/nginx/nginx.conf && \
    echo '    keepalive_timeout 65;' >> /etc/nginx/nginx.conf && \
    echo '    include /etc/nginx/conf.d/*.conf;' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf

# Configure default Nginx site
RUN mkdir -p /etc/nginx/conf.d && \
    echo 'server {' > /etc/nginx/conf.d/default.conf && \
    echo '    listen 80 default_server;' >> /etc/nginx/conf.d/default.conf && \
    echo '    root /var/www/htdocs;' >> /etc/nginx/conf.d/default.conf && \
    echo '    index index.php index.html;' >> /etc/nginx/conf.d/default.conf && \
    echo '    location / {' >> /etc/nginx/conf.d/default.conf && \
    echo '        try_files $uri $uri/ /index.php?$query_string;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '    location ~ \.php$ {' >> /etc/nginx/conf.d/default.conf && \
    echo '        fastcgi_pass 127.0.0.1:9000;' >> /etc/nginx/conf.d/default.conf && \
    echo '        fastcgi_index index.php;' >> /etc/nginx/conf.d/default.conf && \
    echo '        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;' >> /etc/nginx/conf.d/default.conf && \
    echo '        include fastcgi_params;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '    location = /health {' >> /etc/nginx/conf.d/default.conf && \
    echo '        return 200 "healthy\n";' >> /etc/nginx/conf.d/default.conf && \
    echo '        add_header Content-Type text/plain;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '    location = /ping {' >> /etc/nginx/conf.d/default.conf && \
    echo '        fastcgi_pass 127.0.0.1:9000;' >> /etc/nginx/conf.d/default.conf && \
    echo '        include fastcgi_params;' >> /etc/nginx/conf.d/default.conf && \
    echo '    }' >> /etc/nginx/conf.d/default.conf && \
    echo '}' >> /etc/nginx/conf.d/default.conf

# Configure Supervisor
RUN echo '[supervisord]' > /etc/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisord.conf && \
    echo 'logfile=/var/log/supervisor/supervisord.log' >> /etc/supervisord.conf && \
    echo 'pidfile=/var/run/supervisord.pid' >> /etc/supervisord.conf && \
    echo '[program:nginx]' >> /etc/supervisord.conf && \
    echo 'command=nginx -g "daemon off;"' >> /etc/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisord.conf && \
    echo 'priority=10' >> /etc/supervisord.conf && \
    echo '[program:php-fpm]' >> /etc/supervisord.conf && \
    echo 'command=php-fpm --nodaemonize' >> /etc/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisord.conf && \
    echo 'priority=5' >> /etc/supervisord.conf

# Create log directories
RUN mkdir -p /var/log/php /var/log/supervisor

# Set proper permissions
RUN chown -R nginx:nginx /var/www/htdocs && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/tmp/nginx

# Create health check script
RUN echo '#!/bin/sh' > /usr/local/bin/health-check && \
    echo 'if ! pgrep nginx > /dev/null; then' >> /usr/local/bin/health-check && \
    echo '    echo "Nginx is not running"' >> /usr/local/bin/health-check && \
    echo '    exit 1' >> /usr/local/bin/health-check && \
    echo 'fi' >> /usr/local/bin/health-check && \
    echo 'if ! pgrep php-fpm > /dev/null; then' >> /usr/local/bin/health-check && \
    echo '    echo "PHP-FPM is not running"' >> /usr/local/bin/health-check && \
    echo '    exit 1' >> /usr/local/bin/health-check && \
    echo 'fi' >> /usr/local/bin/health-check && \
    echo 'echo "All services are healthy"' >> /usr/local/bin/health-check && \
    echo 'exit 0' >> /usr/local/bin/health-check && \
    chmod +x /usr/local/bin/health-check

# Set working directory
WORKDIR /var/www/htdocs

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /usr/local/bin/health-check

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]