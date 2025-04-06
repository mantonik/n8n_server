#!/bin/bash
echo "Restart cloudflare tunnel"

echo "stop"
systemctl stop cloudflared

echo "start"
systemctl start cloudflared

exit