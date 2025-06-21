#!/bin/bash

# Docker run script for Website Health Monitor
# Alternative to docker-compose for those who prefer docker run commands

IMAGE_NAME="urlcheck-web"
CONTAINER_NAME="urlcheck-web"

echo "🚀 Starting Website Health Monitor with Docker Run..."

# Create necessary directories
echo "📁 Creating directories..."
sudo mkdir -p /data/wwwapp/htdocs
sudo mkdir -p /data/wwwapp/logs/nginx
sudo mkdir -p /data/wwwapp/logs/supervisor

# Set permissions
sudo chown -R 1000:1000 /data/wwwapp/
sudo chmod -R 755 /data/wwwapp/

# Stop and remove existing container if it exists
echo "🛑 Stopping existing container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Build the image if it doesn't exist
if ! docker images | grep -q $IMAGE_NAME; then
    echo "🔨 Building Docker image..."
    docker build -t $IMAGE_NAME .
fi

# Run the container
echo "🚀 Starting container..."
nohup docker run -it --rm \
    --name $CONTAINER_NAME \
    -p 8001:80 \
    -v /data/wwwapp/htdocs:/var/www/html \
    -v /data/wwwapp/logs/nginx:/var/log/nginx \
    -v /data/wwwapp/logs/supervisor:/var/log/supervisor \
    -e DB_HOST=10.20.2.34 \
    -e DB_NAME=n8n_url_healthcheck \
    -e DB_USER=n8nheathcheckusr \
    -e DB_PASS=Edcvfr5687#9ikjJhsg \
    -e APP_ENV=production \
    --restart unless-stopped \
    $IMAGE_NAME > /data/wwwapp/logs/docker.log 2>&1 &

# Wait a moment for container to start
sleep 5

# Check if container is running
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ Container is running successfully!"
    echo ""
    echo "📝 Container Status:"
    docker ps | grep $CONTAINER_NAME
    echo ""
    echo "🌐 Access your application:"
    echo "   • Dashboard: http://$(hostname -I | awk '{print $1}'):8001"
    echo "   • Public Status: http://$(hostname -I | awk '{print $1}'):8001/public.php"
    echo ""
    echo "👤 Default Login:"
    echo "   • Username: admin"
    echo "   • Password: monitor123!"
    echo ""
    echo "📊 Application Directory: /data/wwwapp/htdocs"
    echo "📋 Log Files:"
    echo "   • Docker logs: /data/wwwapp/logs/docker.log"
    echo "   • Nginx access: /data/wwwapp/logs/nginx/access.log"
    echo "   • Nginx error: /data/wwwapp/logs/nginx/error.log"
    echo ""
    echo "🔧 To stop the container:"
    echo "   • docker stop $CONTAINER_NAME"
    echo ""
    echo "🔍 To view logs:"
    echo "   • tail -f /data/wwwapp/logs/docker.log"
    echo "   • docker logs $CONTAINER_NAME"
else
    echo "❌ Container failed to start. Checking logs..."
    cat /data/wwwapp/logs/docker.log
fi