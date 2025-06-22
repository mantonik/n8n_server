#!/bin/bash

# Podman Network Setup Script
# Creates custom network with static IP assignments

NETWORK_NAME="app-network"
NETWORK_SUBNET="10.101.10.0/24"
NETWORK_GATEWAY="10.101.10.1"

# Container IP assignments
WWWAPP_IP="10.10.10.21"

echo "🌐 Setting up Podman Network Infrastructure..."

case "$1" in
    "create")
        echo "📡 Creating custom network: $NETWORK_NAME"
        
        # Remove existing network if it exists
        podman network rm $NETWORK_NAME 2>/dev/null || echo "Network doesn't exist yet"
        
        # Create new network
        podman network create \
            --subnet $NETWORK_SUBNET \
            --gateway $NETWORK_GATEWAY \
            --driver bridge \
            $NETWORK_NAME
        
        echo "✅ Network created successfully"
        echo "   • Network: $NETWORK_NAME"
        echo "   • Subnet: $NETWORK_SUBNET"
        echo "   • Gateway: $NETWORK_GATEWAY"
        ;;
    
    "info")
        echo "📊 Network Information:"
        podman network ls | grep -E "NAME|$NETWORK_NAME"
        echo ""
        echo "📋 Network Details:"
        podman network inspect $NETWORK_NAME 2>/dev/null || echo "Network not found"
        ;;
    
    "list-containers")
        echo "📋 Containers on $NETWORK_NAME:"
        podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter network=$NETWORK_NAME
        ;;
    
    "remove")
        echo "🗑️  Removing network: $NETWORK_NAME"
        
        # Stop containers using this network first
        echo "Checking for containers using this network..."
        CONTAINERS=$(podman ps -q --filter network=$NETWORK_NAME)
        if [ ! -z "$CONTAINERS" ]; then
            echo "Stopping containers using this network..."
            podman stop $CONTAINERS
        fi
        
        # Remove network
        podman network rm $NETWORK_NAME
        echo "✅ Network removed"
        ;;
    
    "test")
        echo "🧪 Testing network connectivity..."
        
        # Check if network exists
        if ! podman network ls | grep -q $NETWORK_NAME; then
            echo "❌ Network $NETWORK_NAME doesn't exist. Run: $0 create"
            exit 1
        fi
        
        # Test with a temporary container
        echo "Creating test container..."
        podman run --rm --network $NETWORK_NAME:ip=$WWWAPP_IP alpine:latest ip addr show
        ;;
    
    *)
        echo "🌐 Podman Network Management"
        echo ""
        echo "Usage: $0 {create|info|list-containers|remove|test}"
        echo ""
        echo "Commands:"
        echo "  create           - Create the custom network"
        echo "  info             - Show network information"
        echo "  list-containers  - List containers on the network"
        echo "  remove           - Remove the network"
        echo "  test             - Test network with temporary container"
        echo ""
        echo "Network Configuration:"
        echo "  📡 Network Name: $NETWORK_NAME"
        echo "  🌐 Subnet: $NETWORK_SUBNET"
        echo "  🚪 Gateway: $NETWORK_GATEWAY"
        echo ""
        echo "IP Assignments:"
        echo "  📱 WWWApp: $WWWAPP_IP"
        echo ""
        echo "Examples:"
        echo "  $0 create    # Create the network"
        echo "  $0 info      # Show network details"
        echo "  $0 test      # Test connectivity"
        ;;
esac