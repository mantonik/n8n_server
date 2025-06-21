#!/bin/bash

# Podman-specific commands for Website Health Monitor
# Since you're using Podman, this script handles Podman-specific quirks

IMAGE_NAME="urlcheck-web"
CONTAINER_NAME="urlcheck-web"

case "$1" in
    "build")
        echo "🔨 Building Podman image..."
        podman build -t $IMAGE_NAME .
        ;;
    
    "start")
        echo "🚀 Starting container with Podman..."
        
        # Create directories
        sudo mkdir -p /data/wwwapp/htdocs /data/wwwapp/logs/{nginx,supervisor}
        sudo chown -R 1000:1000 /data/wwwapp/
        
        # Stop existing container
        podman stop $CONTAINER_NAME 2>/dev/null || true
        podman rm $CONTAINER_NAME 2>/dev/null || true
        
        # Start new container (no --rm flag for Podman with restart policy)
        podman run -d \
            --name $CONTAINER_NAME \
            -p 8001:80 \
            -v /data/wwwapp/htdocs:/var/www/html:Z \
            -v /data/wwwapp/logs/nginx:/var/log/nginx:Z \
            -v /data/wwwapp/logs/supervisor:/var/log/supervisor:Z \
            -e DB_HOST=10.20.2.34 \
            -e DB_NAME=n8n_url_healthcheck \
            -e DB_USER=n8nheathcheckusr \
            -e DB_PASS=Edcvfr5687#9ikjJhsg \
            --restart unless-stopped \
            $IMAGE_NAME
        
        sleep 3
        echo "✅ Container started. Check status with: $0 status"
        ;;
    
    "start-foreground")
        echo "🚀 Starting container in foreground (for debugging)..."
        
        # Create directories
        sudo mkdir -p /data/wwwapp/htdocs /data/wwwapp/logs/{nginx,supervisor}
        sudo chown -R 1000:1000 /data/wwwapp/
        
        # Stop existing container
        podman stop $CONTAINER_NAME 2>/dev/null || true
        podman rm $CONTAINER_NAME 2>/dev/null || true
        
        # Start in foreground for debugging
        podman run --rm \
            --name $CONTAINER_NAME \
            -p 8001:80 \
            -v /data/wwwapp/htdocs:/var/www/html:Z \
            -v /data/wwwapp/logs/nginx:/var/log/nginx:Z \
            -v /data/wwwapp/logs/supervisor:/var/log/supervisor:Z \
            -e DB_HOST=10.20.2.34 \
            -e DB_NAME=n8n_url_healthcheck \
            -e DB_USER=n8nheathcheckusr \
            -e DB_PASS=Edcvfr5687#9ikjJhsg \
            $IMAGE_NAME
        ;;
    
    "stop")
        echo "🛑 Stopping container..."
        podman stop $CONTAINER_NAME
        podman rm $CONTAINER_NAME
        ;;
    
    "restart")
        echo "🔄 Restarting container..."
        $0 stop
        sleep 2
        $0 start
        ;;
    
    "status")
        echo "📊 Container Status:"
        if podman ps | grep -q $CONTAINER_NAME; then
            podman ps | grep $CONTAINER_NAME
            echo ""
            echo "🌐 Application URL: http://$(hostname -I | awk '{print $1}'):8001"
        else
            echo "❌ Container is not running"
            echo "Recent containers:"
            podman ps -a | grep $CONTAINER_NAME | head -3
        fi
        ;;
    
    "logs")
        echo "📋 Container Logs:"
        podman logs --tail=50 -f $CONTAINER_NAME
        ;;
    
    "shell")
        echo "🐚 Entering container shell..."
        podman exec -it $CONTAINER_NAME /bin/sh
        ;;
    
    "nginx-logs")
        echo "📋 Nginx Access Logs:"
        tail -f /data/wwwapp/logs/nginx/access.log
        ;;
    
    "error-logs")
        echo "📋 Nginx Error Logs:"
        tail -f /data/wwwapp/logs/nginx/error.log
        ;;
    
    "clean")
        echo "🧹 Cleaning up..."
        podman stop $CONTAINER_NAME 2>/dev/null || true
        podman rm $CONTAINER_NAME 2>/dev/null || true
        podman rmi $IMAGE_NAME 2>/dev/null || true
        echo "✅ Cleanup complete"
        ;;
    
    "rebuild")
        echo "🔄 Rebuilding container..."
        $0 stop
        podman rmi $IMAGE_NAME 2>/dev/null || true
        $0 build
        $0 start
        ;;
    
    "debug")
        echo "🔍 Debug information:"
        echo "Podman version:"
        podman --version
        echo ""
        echo "Container status:"
        podman ps -a | grep $CONTAINER_NAME || echo "No container found"
        echo ""
        echo "Recent logs:"
        podman logs --tail=20 $CONTAINER_NAME 2>/dev/null || echo "No logs available"
        echo ""
        echo "Directory permissions:"
        ls -la /data/wwwapp/
        ;;
    
    "test-config")
        echo "🧪 Testing configuration files..."
        
        # Check if config files exist
        files=("nginx.conf" "default.conf" "supervisord.conf")
        for file in "${files[@]}"; do
            if [ -f "$file" ]; then
                echo "✅ $file exists"
            else
                echo "❌ $file missing"
            fi
        done
        
        # Test nginx config syntax
        if [ -f "nginx.conf" ] && [ -f "default.conf" ]; then
            echo "Testing nginx configuration..."
            podman run --rm -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:Z -v $(pwd)/default.conf:/etc/nginx/conf.d/default.conf:Z nginx:alpine nginx -t 2>/dev/null && echo "✅ Nginx config valid" || echo "❌ Nginx config invalid"
        fi
        ;;
    
    *)
        echo "🐳 Website Health Monitor - Podman Management"
        echo ""
        echo "Usage: $0 {build|start|start-foreground|stop|restart|status|logs|shell|nginx-logs|error-logs|clean|rebuild|debug|test-config}"
        echo ""
        echo "Commands:"
        echo "  build            - Build the Podman image"
        echo "  start            - Start the container in background"
        echo "  start-foreground - Start the container in foreground (for debugging)"
        echo "  stop             - Stop the container"
        echo "  restart          - Restart the container"
        echo "  status           - Show container status"
        echo "  logs             - Show container logs (live)"
        echo "  shell            - Enter container shell"
        echo "  nginx-logs       - Show nginx access logs (live)"
        echo "  error-logs       - Show nginx error logs (live)"
        echo "  clean            - Remove container and image"
        echo "  rebuild          - Stop, rebuild, and start"
        echo "  debug            - Show debug information"
        echo "  test-config      - Test configuration files"
        echo ""
        echo "Podman-specific features:"
        echo "  • Uses :Z flag for SELinux compatibility"
        echo "  • Handles restart policies correctly"
        echo "  • Includes foreground mode for debugging"
        echo ""
        echo "Examples:"
        echo "  $0 build && $0 start"
        echo "  $0 start-foreground  # For debugging"
        echo "  $0 debug"
        ;;
esac