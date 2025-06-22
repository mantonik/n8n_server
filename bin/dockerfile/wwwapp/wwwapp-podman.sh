#!/bin/bash

# Podman commands for WWWApp (Website Health Monitor)
# Updated for correct directory structure: /data/docker/wwwapp
# Network enabled with static IP support

IMAGE_NAME="wwwapp"
CONTAINER_NAME="wwwapp"
BASE_PATH="/data/docker/wwwapp"
NETWORK_NAME="app-network"
WWWAPP_IP="10.101.10.21"

case "$1" in
    "build")
        echo "🔨 Building WWWApp Podman image..."
        podman build -t $IMAGE_NAME .
        ;;
    
    "start")
        echo "🚀 Starting WWWApp container with static IP..."
        
        # Create directories if they don't exist
        sudo mkdir -p $BASE_PATH/var/{www/html,logs/{nginx,supervisor}}
        sudo chown -R 1000:1000 $BASE_PATH/
        
        # Check if network exists
        if ! podman network ls | grep -q $NETWORK_NAME; then
            echo "❌ Network $NETWORK_NAME doesn't exist"
            echo "📡 Create network first with: ./setup-network.sh create"
            exit 1
        fi
        
        # Stop existing container
        podman stop $CONTAINER_NAME 2>/dev/null || true
        podman rm $CONTAINER_NAME 2>/dev/null || true
        
        # Start container with static IP on custom network
        # 
        #      -e DB_HOST=10.20.2.34 \
        #   -e DB_NAME=n8n_url_healthcheck \
        #   -e DB_USER=n8nheathcheckusr \
        #   -e DB_PASS=Edcvfr5687#9ikjJhsg \
        #   
        podman run -d \
            --name $CONTAINER_NAME \
            --network $NETWORK_NAME:ip=$WWWAPP_IP \
            -p 8001:80 \
            -v $BASE_PATH/var/www/html:/var/www/html:Z \
            -v $BASE_PATH/var/logs/nginx:/var/log/nginx:Z \
            -v $BASE_PATH/var/logs/supervisor:/var/log/supervisor:Z \
            -v $BASE_PATH/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:Z \
            -v $BASE_PATH/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:Z \
            --restart unless-stopped \
            $IMAGE_NAME
        
        sleep 3
        echo "✅ WWWApp container started with static IP: $WWWAPP_IP"
        echo "📍 Network: $NETWORK_NAME"
        ;;
    
    "start-bridge")
        echo "🚀 Starting WWWApp container on default bridge network..."
        
        # Create directories if they don't exist
        sudo mkdir -p $BASE_PATH/var/{www/html,logs/{nginx,supervisor}}
        sudo chown -R 1000:1000 $BASE_PATH/
        
        # Stop existing container
        podman stop $CONTAINER_NAME 2>/dev/null || true
        podman rm $CONTAINER_NAME 2>/dev/null || true
        
        # Start container on default bridge network (fallback)
        # 
        #      -e DB_HOST=10.20.2.34 \
        #   -e DB_NAME=n8n_url_healthcheck \
        #   -e DB_USER=n8nheathcheckusr \
        #   -e DB_PASS=Edcvfr5687#9ikjJhsg \
        #   
        podman run -d \
            --name $CONTAINER_NAME \
            -p 8001:80 \
            -v $BASE_PATH/var/www/html:/var/www/html:Z \
            -v $BASE_PATH/var/logs/nginx:/var/log/nginx:Z \
            -v $BASE_PATH/var/logs/supervisor:/var/log/supervisor:Z \
            -v $BASE_PATH/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:Z \
            -v $BASE_PATH/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:Z \
            --restart unless-stopped \
            $IMAGE_NAME
        
        sleep 3
        echo "✅ WWWApp container started on bridge network"
        ;;
    
    "start-debug")
        echo "🚀 Starting WWWApp container in debug mode..."
        
        # Stop existing container
        podman stop $CONTAINER_NAME 2>/dev/null || true
        podman rm $CONTAINER_NAME 2>/dev/null || true
        
        # Check if network exists and set network config
        if podman network ls | grep -q $NETWORK_NAME; then
            NETWORK_CONFIG="--network $NETWORK_NAME:ip=$WWWAPP_IP"
            echo "Using custom network with IP: $WWWAPP_IP"
        else
            NETWORK_CONFIG=""
            echo "Using default bridge network (custom network not found)"
        fi
        
        # Start in foreground for debugging
        # 
        #           -e DB_HOST=10.20.2.34 \
        #   -e DB_NAME=n8n_url_healthcheck \
        #   -e DB_USER=n8nheathcheckusr \
        #   -e DB_PASS=Edcvfr5687#9ikjJhsg \
        podman run --rm \
            --name $CONTAINER_NAME-debug \
            $NETWORK_CONFIG \
            -p 8001:80 \
            -v $BASE_PATH/var/www/html:/var/www/html:Z \
            -v $BASE_PATH/var/logs/nginx:/var/log/nginx:Z \
            -v $BASE_PATH/var/logs/supervisor:/var/log/supervisor:Z \
            -v $BASE_PATH/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:Z \
            -v $BASE_PATH/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:Z \
            $IMAGE_NAME
        ;;
    
    "stop")
        echo "🛑 Stopping WWWApp container..."
        podman stop $CONTAINER_NAME
        podman rm $CONTAINER_NAME
        ;;
    
    "restart")
        echo "🔄 Restarting WWWApp container..."
        $0 stop
        sleep 2
        $0 start
        ;;
    
    "status")
        echo "📊 WWWApp Container Status:"
        if podman ps | grep -q $CONTAINER_NAME; then
            podman ps | grep $CONTAINER_NAME
            echo ""
            
            # Get container IP
            CONTAINER_IP=$(podman inspect $CONTAINER_NAME --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || echo "unknown")
            if [ "$CONTAINER_IP" != "unknown" ] && [ ! -z "$CONTAINER_IP" ]; then
                echo "📍 Container IP: $CONTAINER_IP"
                if [ "$CONTAINER_IP" = "$WWWAPP_IP" ]; then
                    echo "✅ Static IP assigned correctly"
                fi
            fi
            
            # Check if port is actually listening
            if netstat -tlnp | grep -q :8001; then
                echo "✅ Port 8001 is listening"
            else
                echo "❌ Port 8001 is NOT listening"
            fi
            
            echo ""
            echo "🌐 Application URLs (external access):"
            echo "   • Main App: http://$(hostname -I | awk '{print $1}'):8001"
            echo "   • URL Health Check: http://$(hostname -I | awk '{print $1}'):8001/urlcheck/"
            echo "   • Test Page: http://$(hostname -I | awk '{print $1}'):8001/index.php"
            echo ""
            echo "🌐 Application URLs (from server):"
            echo "   • Main App: curl -v http://localhost:8001/"
            echo "   • URL Health Check: curl -v http://localhost:8001/urlcheck/"
            echo "   • Test Page: curl -v http://localhost:8001/index.php"
            echo "   • Health Check: curl -v http://localhost:8001/health"
            
            # If on custom network, show internal communication
            if [ "$CONTAINER_IP" != "unknown" ] && [ ! -z "$CONTAINER_IP" ]; then
                echo ""
                echo "🔗 Internal Network Access (from other containers):"
                echo "   • curl http://$CONTAINER_IP/"
                echo "   • curl http://$CONTAINER_IP/health"
                echo "   • curl http://$CONTAINER_IP/urlcheck/"
            fi
            
            echo ""
            echo "🔍 Debug Commands:"
            echo "   $0 logs          # View container logs"
            echo "   $0 shell         # Enter container"
            echo "   $0 nginx-logs    # View nginx access logs"
            echo "   $0 error-logs    # View nginx error logs"
            echo "   $0 network-info  # Show network details"
            echo ""
            
        else
            echo "❌ Container is not running"
            echo "Recent containers:"
            podman ps -a | grep $CONTAINER_NAME | head -3
            echo ""
            echo "🚀 Start Commands:"
            echo "   $0 start         # Start with custom network (recommended)"
            echo "   $0 start-bridge  # Start with bridge network"
            echo "   $0 start-debug   # Start in foreground (see errors)"
            echo "   $0 rebuild       # Rebuild and start"
        fi
        ;;
    
    "network-info")
        echo "🌐 Network Information:"
        echo ""
        echo "📡 Available Networks:"
        podman network ls
        echo ""
        if podman network ls | grep -q $NETWORK_NAME; then
            echo "📋 Custom Network Details:"
            podman network inspect $NETWORK_NAME
            echo ""
            echo "🔗 Containers on $NETWORK_NAME:"
            podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}" --filter network=$NETWORK_NAME
        else
            echo "❌ Custom network '$NETWORK_NAME' not found"
            echo "📡 Create it with: ./setup-network.sh create"
        fi
        ;;
    
    "logs")
        echo "📋 WWWApp Container Logs:"
        podman logs --tail=50 -f $CONTAINER_NAME
        ;;
    
    "shell")
        echo "🐚 Entering WWWApp container shell..."
        podman exec -it $CONTAINER_NAME /bin/sh
        ;;
    
    "nginx-logs")
        echo "📋 Nginx Access Logs:"
        tail -f $BASE_PATH/var/logs/nginx/access.log
        ;;
    
    "error-logs")
        echo "📋 Nginx Error Logs:"
        tail -f $BASE_PATH/var/logs/nginx/error.log
        ;;
    
    "supervisor-logs")
        echo "📋 Supervisor Logs:"
        tail -f $BASE_PATH/var/logs/supervisor/supervisord.log
        ;;
    
    "test-app")
        echo "🧪 Testing WWWApp endpoints..."
        
        echo "Testing main page..."
        curl -s -o /dev/null -w "Main page: %{http_code}\n" http://localhost:8001/
        
        echo "Testing PHP info..."
        curl -s -o /dev/null -w "PHP info: %{http_code}\n" http://localhost:8001/index.php
        
        echo "Testing URL Health Check..."
        curl -s -o /dev/null -w "Health Monitor Login: %{http_code}\n" http://localhost:8001/urlcheck/
        
        echo "Testing Health Check Public..."
        curl -s -o /dev/null -w "Public Status: %{http_code}\n" http://localhost:8001/urlcheck/public.php
        ;;
    
    "clean")
        echo "🧹 Cleaning up WWWApp..."
        podman stop $CONTAINER_NAME 2>/dev/null || true
        podman rm $CONTAINER_NAME 2>/dev/null || true
        podman rmi $IMAGE_NAME 2>/dev/null || true
        echo "✅ Cleanup complete"
        ;;
    
    "rebuild")
        echo "🔄 Rebuilding WWWApp container..."
        $0 stop
        podman rmi $IMAGE_NAME 2>/dev/null || true
        $0 build
        $0 start
        ;;
    
    "info")
        echo "ℹ️  WWWApp Container Information:"
        echo "   • Image Name: $IMAGE_NAME"
        echo "   • Container Name: $CONTAINER_NAME"
        echo "   • Port: 8001"
        echo "   • Base Path: $BASE_PATH"
        echo "   • Network: $NETWORK_NAME"
        echo "   • Static IP: $WWWAPP_IP"
        echo ""
        echo "📁 Directory Structure:"
        echo "   • App Files: $BASE_PATH/var/www/html/"
        echo "   • URL Health Check: $BASE_PATH/var/www/html/urlcheck/"
        echo "   • Logs: $BASE_PATH/var/logs/"
        echo "   • Nginx Config: $BASE_PATH/etc/nginx/"
        echo ""
        echo "🌐 Application URLs:"
        echo "   • Main: http://server:8001/"
        echo "   • Health Monitor: http://server:8001/urlcheck/"
        echo "   • Public Status: http://server:8001/urlcheck/public.php"
        echo ""
        echo "🔗 Network Configuration:"
        echo "   • Network: $NETWORK_NAME"
        echo "   • Static IP: $WWWAPP_IP"
        echo "   • Subnet: 10.101.10.0/24"
        ;;
    
    "check-files")
        echo "📋 Checking WWWApp file structure..."
        
        echo "Main app directory:"
        ls -la $BASE_PATH/var/www/html/ 2>/dev/null || echo "❌ Directory not found"
        
        echo -e "\nURL Health Check files:"
        ls -la $BASE_PATH/var/www/html/urlcheck/ 2>/dev/null || echo "❌ urlcheck directory not found"
        
        echo -e "\nNginx config:"
        ls -la $BASE_PATH/etc/nginx/ 2>/dev/null || echo "❌ nginx config directory not found"
        
        echo -e "\nLog directories:"
        ls -la $BASE_PATH/var/logs/ 2>/dev/null || echo "❌ logs directory not found"
        ;;
    
    *)
        echo "🐳 WWWApp (Website Health Monitor) - Podman Management"
        echo ""
        echo "Usage: $0 {build|start|start-bridge|start-debug|stop|restart|status|logs|shell|test-app|info|check-files|clean|rebuild|network-info}"
        echo ""
        echo "Network Commands:"
        echo "  start        - Start with custom network (IP: $WWWAPP_IP)"
        echo "  start-bridge - Start with default bridge network"
        echo "  network-info - Show network information"
        echo ""
        echo "Container Commands:"
        echo "  build        - Build the WWWApp image"
        echo "  start-debug  - Start in foreground (for debugging)"
        echo "  stop         - Stop the container"
        echo "  restart      - Restart the container"
        echo "  status       - Show container status and URLs"
        echo "  logs         - Show container logs (live)"
        echo "  shell        - Enter container shell"
        echo "  test-app     - Test all application endpoints"
        echo "  info         - Show configuration info"
        echo "  check-files  - Check file structure"
        echo "  clean        - Remove container and image"
        echo "  rebuild      - Stop, rebuild, and start"
        echo ""
        echo "Log Commands:"
        echo "  nginx-logs      - Show nginx access logs"
        echo "  error-logs      - Show nginx error logs"
        echo "  supervisor-logs - Show supervisor logs"
        echo ""
        echo "Network Configuration:"
        echo "  📡 Network Name: $NETWORK_NAME"
        echo "  📍 Static IP: $WWWAPP_IP"
        echo "  🌐 Subnet: 10.101.10.0/24"
        echo ""
        echo "Application Structure:"
        echo "  📁 $BASE_PATH/var/www/html/         - Main web directory"
        echo "  📁 $BASE_PATH/var/www/html/urlcheck/ - Health monitor app"
        echo "  📁 $BASE_PATH/var/logs/              - Application logs"
        echo ""
        echo "Access URLs:"
        echo "  🌐 http://server:8001/               - Main app"
        echo "  🌐 http://server:8001/urlcheck/      - Health monitor"
        echo ""
        echo "Examples:"
        echo "  ./setup-network.sh create  # Create custom network first"
        echo "  $0 build && $0 start       # Build and start with static IP"
        echo "  $0 test-app                # Test all endpoints"
        echo "  $0 network-info            # Show network details"
        ;;
esac