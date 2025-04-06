#!/bin/bash

CONFIG_FILE=~/etc/cloudflare.cfg

# Load config if it exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Reading configuration from $CONFIG_FILE..."
    source "$CONFIG_FILE"
else
    echo "Configuration file not found. Prompting for input..."
fi

# Prompt for values if not set
: "${ACCOUNT_ID:=$(read -p "Enter ACCOUNT_ID: " val && echo $val)}"
: "${ZONE_ID:=$(read -p "Enter ZONE_ID: " val && echo $val)}"
: "${CLOUDFLARE_API_TOKEN:=$(read -p "Enter CLOUDFLARE_API_TOKEN: " val && echo $val)}"
: "${DNS_HOSTNAME:=$(read -p "Enter DNS_HOSTNAME (e.g. tunnel.example.com): " val && echo $val)}"
: "${LOCAL_NETWORK_IP:=$(read -p "Enter LOCAL_NETWORK_IP (e.g. 127.0.0.1): " val && echo $val)}"
: "${LOCALHOST_PORT:=80}"

export ACCOUNT_ID ZONE_ID CLOUDFLARE_API_TOKEN DNS_HOSTNAME LOCAL_NETWORK_IP LOCALHOST_PORT

DT=`date +%Y%m%d%H%M`
echo "1. Verifying API Token..."
curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" | jq .

echo "2. Creating tunnel..."
TUNNEL_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel" \
     -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data "{\"name\":\"${DNS_HOSTNAME}-tunnel\",\"config_src\":\"cloudflare\"}")

TUNNEL_ID=$(echo "$TUNNEL_RESPONSE" | jq -r '.result.id')
TUNNEL_TOKEN=$(echo "$TUNNEL_RESPONSE" | jq -r '.result.token')

echo "Tunnel ID: $TUNNEL_ID"
echo "Tunnel Token: $TUNNEL_TOKEN"

echo "3. Creating tunnel config..."
curl -s --request PUT \
"https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
--header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
--header "Content-Type: application/json" \
--data "{
  \"config\": {
    \"ingress\": [
      {
        \"hostname\": \"$DNS_HOSTNAME\",
        \"service\": \"http://$localhost:$LOCALHOST_PORT\"
      },
      {
        \"service\": \"http_status:404\"
      }
    ]
  }
}" | jq .

echo "4. Installing cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    sudo apt update && sudo apt install -y cloudflared || \
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb && \
    sudo dpkg -i cloudflared.deb
fi

echo "5. Saving credentials..."
mkdir -p ~/.cloudflared
echo "$TUNNEL_TOKEN" > ~/.cloudflared/${TUNNEL_ID}.json

echo "tunnel: $TUNNEL_ID
credentials-file: /home/$USER/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: $DNS_HOSTNAME
    service: http://$LOCAL_NETWORK_IP:$LOCALHOST_PORT
  - service: http_status:404
" > ~/.cloudflared/config.yml

echo "6. Running tunnel..."
cloudflared tunnel run "$TUNNEL_ID"

echo "Validate tunnel"
echo ""
curl https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
echo ""


