#!/bin/bash

# Configuration (replace with your values)
API_TOKEN="YOUR_CLOUDFLARE_API_TOKEN"
ZONE_ID="YOUR_CLOUDFLARE_ZONE_ID"
RECORD_NAME="n8nlocal.dmcloudarchitect.com"
RECORD_TYPE="A"  # Or "AAAA" for IPv6
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME&type=$RECORD_TYPE" \
             -H "Authorization: Bearer $API_TOKEN" \
             -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ -z "$RECORD_ID" ]; then
  echo "DNS record not found."
  exit 1
fi

# Get public IP address (IPv4)
PUBLIC_IP=$(curl -s https://api.ipify.org)

# Check if we got an ip
if [ -z "$PUBLIC_IP" ]; then
    echo "Could not get public ip"
    exit 1
fi

# Store the IP in a file
IP_FILE="/tmp/current_ip_$RECORD_NAME.txt"

# Create the file if it doesn't exist
if [ ! -f "$IP_FILE" ]; then
  touch "$IP_FILE"
fi

# Read the previous IP from the file
PREVIOUS_IP=$(cat "$IP_FILE" 2>/dev/null)

# Get current time
CURRENT_TIME=$(date +%s)
LAST_UPDATE=$(stat -c %Y "$IP_FILE" 2>/dev/null) #get the last modification time of the IP_FILE

#calculate the difference
DIFF=$((CURRENT_TIME - LAST_UPDATE))

# 86400 seconds = 1 day
if [ "$PUBLIC_IP" != "$PREVIOUS_IP" ] || [ "$DIFF" -gt 86400 ]; then
  # Update DNS record
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$PUBLIC_IP\",\"ttl\":120,\"proxied\":false}"

  if [ $? -eq 0 ]; then
    echo "DNS record updated to $PUBLIC_IP"
    # Update the IP file
    echo "$PUBLIC_IP" > "$IP_FILE"
  else
    echo "Failed to update DNS record"
    exit 1
  fi
else
  echo "IP address has not changed and last update was less than 24 hours ago. No update needed."
fi

exit 0