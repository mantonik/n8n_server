#!/bin/bash 

#script will setup a cloudflare tunnel 
# requirement - API key 
# follow below to get API key 
# https://developers.cloudflare.com/fundamentals/api/get-started/create-token/ 

# Create tunnel API
# https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel-api/
#



echo "1. Create API KEY "

echo "Token validation"
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer h7vCh632jCtMP8MYx9aVu9MVIEA8_Z6kaBNYtfZA" \
     -H "Content-Type:application/json"


ACCOUNT_ID="f1a970516fcb8b6903a95f2c46f2df50"
CLOUDFLARE_API_TOKEN="h7vCh632jCtMP8MYx9aVu9MVIEA8_Z6kaBNYtfZA"
ZONE_ID="4d4eb5c7680711db1ab2f01e4b8d142e"
export ACCOUNT_ID CLOUDFLARE_API_TOKEN ZONE_ID


echo "2. Create tunnel "

curl "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
--data '{
  "name": "api-tunnel",
  "config_src": "cloudflare"
}'

# response
{
  "success": true,
  "errors": [],
  "messages": [],
  "result": {
    "id": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3",
    "account_tag": "f1a970516fcb8b6903a95f2c46f2df50",
    "created_at": "2025-04-05T12:03:56.299061Z",
    "deleted_at": null,
    "name": "api-tunnel",
    "connections": [],
    "conns_active_at": null,
    "conns_inactive_at": "2025-04-05T12:03:56.299061Z",
    "tun_type": "cfd_tunnel",
    "metadata": {},
    "status": "inactive",
    "remote_config": true,
    "credentials_file": {
      "AccountTag": "f1a970516fcb8b6903a95f2c46f2df50",
      "TunnelID": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3",
      "TunnelName": "api-tunnel",
      "TunnelSecret": "8c98/2atadtSO5PQMWYBhCLOojVqavaCB3KEU2LhzOAXha4yqwM9yKzVlbtdaPTiooxhYw/QGtay9aGQV1msvw=="
    },
    "token": "eyJhIjoiZjFhOTcwNTE2ZmNiOGI2OTAzYTk1ZjJjNDZmMmRmNTAiLCJ0IjoiNmMxYTFkNWEtMDRiNy00ZjE2LTk5NWQtNDMyYjI1OGRiYWYzIiwicyI6IjhjOTgvMmF0YWR0U081UFFNV1lCaENMT29qVnFhdmFDQjNLRVUyTGh6T0FYaGE0eXF3TTl5S3pWbGJ0ZGFQVGlvb3hoWXcvUUd0YXk5YUdRVjFtc3Z3PT0ifQ=="
  }
}

Tunnel_ID="6c1a1d5a-04b7-4f16-995d-432b258dbaf3"
export Tunnel_ID

echo "3a. Connect an application"
echo "Add website to Cloufflare"

DNS_HOSTNAME="n8ndev.dmcloudarchitect.com"
export DNS_HOSTNAME

curl --request PUT \
"https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$Tunnel_ID/configurations" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
--data '{
  "config": {
    "ingress": [
      {
        "hostname": "n8ndev.dmcloudarchitect.com",
        "service": "http://localhost:80",
        "originRequest": {}
      },
      {
        "service": "http_status:404"
      }
    ]
  }
}'

#Response
{
  "success": true,
  "errors": [],
  "messages": [],
  "result": {
    "tunnel_id": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3",
    "version": 1,
    "config": {
      "ingress": [
        {
          "service": "http://localhost:80",
          "hostname": "n8ndev.dmcloudarchitect.com",
          "originRequest": {}
        },
        {
          "service": "http_status:404"
        }
      ],
      "warp-routing": {
        "enabled": false
      }
    },
    "source": "cloudflare",
    "created_at": "2025-04-05T12:10:42.626571Z"
  }
}

echo "Create DNS record"

curl "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
--data '{
  "type": "CNAME",
  "proxied": true,
  "name": "n8ndev.dmcloudarchitect.com",
  "content": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3.cfargotunnel.com"
}'



response 
{
  "result": {
    "id": "f4b7fc7c9c9eafeb92744892e5ca2c70",
    "name": "n8ndev.dmcloudarchitect.com",
    "type": "CNAME",
    "content": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3.cfargotunnel.com",
    "proxiable": true,
    "proxied": true,
    "ttl": 1,
    "settings": {
      "flatten_cname": false
    },
    "meta": {},
    "comment": null,
    "tags": [],
    "created_on": "2025-04-05T12:23:01.794542Z",
    "modified_on": "2025-04-05T12:23:01.794542Z"
  },
  "success": true,
  "errors": [],
  "messages": []
}



echo "3b. Connect a network"

curl "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/teamnet/routes" \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
--data '{
  "network": "192.168.10.0/24",
  "tunnel_id": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3",
  "comment": "Home private network route"
}'


response 
{
  "success": true,
  "errors": [],
  "messages": [],
  "result": {
    "id": "2dff6a48-bb07-47ba-b5e8-f21deb13fa7b",
    "tun_type": "cfd_tunnel",
    "network": "192.168.10.0/24",
    "tunnel_id": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3",
    "comment": "Home private network route",
    "created_at": "2025-04-05T12:25:28.793238Z",
    "deleted_at": null,
    "virtual_network_id": "11e7eda0-e8c5-4e30-ae84-e78cfc950bd8"
  }
}








# Add cloudflared.repo to /etc/yum.repos.d/ 
curl -fsSl https://pkg.cloudflare.com/cloudflared-ascii.repo | sudo tee /etc/yum.repos.d/cloudflared.repo

#update repo
sudo yum -y update

# install cloudflared
sudo yum -y install cloudflared


cloudflared service install eyJhIjoiZjFhOTcwNTE2ZmNiOGI2OTAzYTk1ZjJjNDZmMmRmNTAiLCJ0IjoiNmMxYTFkNWEtMDRiNy00ZjE2LTk5NWQtNDMyYjI1OGRiYWYzIiwicyI6IjhjOTgvMmF0YWR0U081UFFNV1lCaENMT29qVnFhdmFDQjNLRVUyTGh6T0FYaGE0eXF3TTl5S3pWbGJ0ZGFQVGlvb3hoWXcvUUd0YXk5YUdRVjFtc3Z3PT0ifQ==


echo "Validate tunnel"
curl https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/6c1a1d5a-04b7-4f16-995d-432b258dbaf3 \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CLOUDFLARE_API_TOKEN"


{
  "success": true,
  "errors": [],
  "messages": [],
  "result": {
    "id": "6c1a1d5a-04b7-4f16-995d-432b258dbaf3",
    "account_tag": "f1a970516fcb8b6903a95f2c46f2df50",
    "created_at": "2025-04-05T12:03:56.299061Z",
    "deleted_at": null,
    "name": "api-tunnel",
    "connections": [
      {
        "colo_name": "ewr14",
        "uuid": "a250d303-8fbd-4791-a761-cf4347b0c018",
        "id": "a250d303-8fbd-4791-a761-cf4347b0c018",
        "is_pending_reconnect": false,
        "origin_ip": "100.8.176.232",
        "opened_at": "2025-04-05T12:27:16.395410Z",
        "client_id": "87f61f69-007c-4e69-a386-67141dce7917",
        "client_version": "2025.4.0"
      },
      {
        "colo_name": "ewr05",
        "uuid": "eeeb2d70-9022-4b44-bf04-cc968a8e2b9a",
        "id": "eeeb2d70-9022-4b44-bf04-cc968a8e2b9a",
        "is_pending_reconnect": false,
        "origin_ip": "100.8.176.232",
        "opened_at": "2025-04-05T12:27:16.671888Z",
        "client_id": "87f61f69-007c-4e69-a386-67141dce7917",
        "client_version": "2025.4.0"
      },
      {
        "colo_name": "ewr14",
        "uuid": "1743f84f-f247-41fd-94ea-1a1986e1f857",
        "id": "1743f84f-f247-41fd-94ea-1a1986e1f857",
        "is_pending_reconnect": false,
        "origin_ip": "100.8.176.232",
        "opened_at": "2025-04-05T12:27:17.599486Z",
        "client_id": "87f61f69-007c-4e69-a386-67141dce7917",
        "client_version": "2025.4.0"
      },
      {
        "colo_name": "ewr11",
        "uuid": "a9d9ec08-2676-4683-8e0c-d99615b69de0",
        "id": "a9d9ec08-2676-4683-8e0c-d99615b69de0",
        "is_pending_reconnect": false,
        "origin_ip": "100.8.176.232",
        "opened_at": "2025-04-05T12:27:18.512678Z",
        "client_id": "87f61f69-007c-4e69-a386-67141dce7917",
        "client_version": "2025.4.0"
      }
    ],
    "conns_active_at": "2025-04-05T12:27:16.395410Z",
    "conns_inactive_at": null,
    "tun_type": "cfd_tunnel",
    "metadata": {},
    "status": "healthy",
    "remote_config": true
  }
}