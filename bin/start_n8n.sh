#!/bin/bash 

#enable debug mode 
if [ $1"x" == "dx" ]; then 
    set -x 
fi 

# Load enviremnet file 
. ~/etc/n8n.cfg

#docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n &

#Stop n8n application
docker stop n8n

#Pull latest version
docker pull docker.n8n.io/n8nio/n8n

#start n8n
#docker run -it --rm \
#    --name n8n \
#    -p 5678:5678 \
#    -e  WEBHOOK_URL=https://dmseo03.dmcloudarchitect.com/ \
#    -v n8n_data:/home/node/.n8n \
#    docker.n8n.io/n8nio/n8n &


docker run -it --rm \
    --name n8n \
    -p 5678:5678 \
    -e  WEBHOOK_URL=https://dmseo03.dmcloudarchitect.com/ \
    -v n8n_data:/home/node/.n8n \
    -e N8N_EMAIL_MODE=smtp \
    -e N8N_SMTP_HOST=${SMTP_HOST} \
    -e N8N_SMTP_PORT=${SMTP_PORT} \
    -e N8N_SMTP_USER=${SMTP_USER} \
    -e N8N_SMTP_PASS=${SMTP_API_KEY} \
    -e N8N_SMTP_SENDER=${SMTP_SENDER} \
    -e N8N_SMTP_SSL=true \
    docker.n8n.io/n8nio/n8n &