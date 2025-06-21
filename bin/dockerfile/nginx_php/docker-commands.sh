#!/bin/bash

# Docker Commands for Website Health Monitor
# Collection of useful docker commands for management

IMAGE_NAME="urlcheck-web"
CONTAINER_NAME="urlcheck-web"

case "$1" in
    "build")
        echo "🔨 Building Docker image..."
        docker build -t $IMAGE_NAME .
        ;;
    
    "start")
        echo "🚀 Starting container..."
        
        # Create directories
        sudo mkdir -p /data/wwwapp/htdocs /data/wwwapp/logs/{nginx,supervisor}
        sudo chown -R 1000:1000 /data/wwwapp/
        
        # Stop existing container
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        
        # Start new container
        nohup docker run -d \
            --name $CONTAINER_NAME \
            -p 8001:80 \
            -v /data/wwwapp/htdocs:/var/www/html \
            -v /data/wwwapp/logs/nginx:/var/log/nginx \
            -v /data/wwwapp/logs/supervisor:/var/log/supervisor \
            -e DB_HOST=10.20.2.34 \
            -e DB_NAME=n8n_url_healthcheck \
            -e DB_USER=n8nheathcheckusr \
            -e DB_PASS=Edcvfr5687#9ikjJhsg \
            --restart unless-stopped \
            $IMAGE_NAME > /data/wwwapp/logs/docker-start.log 2>&1 &
        
        sleep 3
        echo "✅ Container started. Check status with: $0 status"
        ;;
    
    "stop")
        echo "🛑 Stopping container..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
        ;;
    
    "restart")
        echo "🔄 Restarting container..."
        $0 stop
        sleep 2
        $0 start
        ;;
    
    "status")
        echo "📊 Container Status:"
        if docker ps | grep -q $CONTAINER_NAME; then
            docker ps | grep $CONTAINER_NAME
            echo ""
            echo "🌐 Application URL: http://$(hostname -I | awk '{print $1}'):8001"
        else
            echo "❌ Container is not running"
            echo "Recent containers:"
            docker ps -a | grep $CONTAINER_NAME | head -3
        fi
        ;;
    
    "logs")
        echo "📋 Container Logs:"
        docker logs --tail=50 -f $CONTAINER_NAME
        ;;
    
    "shell")
        echo "🐚 Entering container shell..."
        docker exec -it $CONTAINER_NAME /bin/sh
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
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        docker rmi $IMAGE_NAME 2>/dev/null || true
        echo "✅ Cleanup complete"
        ;;
    
    "rebuild")
        echo "🔄 Rebuilding container..."
        $0 stop
        docker rmi $IMAGE_NAME 2>/dev/null || true
        $0 build
        $0 start
        ;;
    
    "info")
        echo "ℹ️  Container Information:"
        echo "   • Image Name: $IMAGE_NAME"
        echo "   • Container Name: $CONTAINER_NAME"
        echo "   • Port: 8001"
        echo "   • App Directory: /data/wwwapp/htdocs"
        echo "   • Log Directory: /data/wwwapp/logs"
        echo ""
        echo "📁 Directory Structure:"
        ls -la /data/wwwapp/ 2>/dev/null || echo "   Directory not created yet"
        ;;
    
    *)
        echo "🐳 Website Health Monitor Docker Management"
        echo ""
        echo "Usage: $0 {build|start|stop|restart|status|logs|shell|nginx-logs|error-logs|clean|rebuild|info}"
        echo ""
        echo "Commands:"
        echo "  build      - Build the Docker image"
        echo "  start      - Start the container"
        echo "  stop       - Stop the container"
        echo "  restart    - Restart the container"
        echo "  status     - Show container status"
        echo "  logs       - Show container logs (live)"
        echo "  shell      - Enter container shell"
        echo "  nginx-logs - Show nginx access logs (live)"
        echo "  error-logs - Show nginx error logs (live)"
        echo "  clean      - Remove container and image"
        echo "  rebuild    - Stop, rebuild, and start"
        echo "  info       - Show configuration info"
        echo ""
        echo "Examples:"
        echo "  $0 build && $0 start"
        echo "  $0 status"
        echo "  $0 logs"
        ;;
esac