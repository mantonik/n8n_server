#!/bin/bash 
# 12/13/24 add prune command
# 12/13/24 MA add log location, and rotate log on start 

# load profile 
. /etc/profile 

#enable debug mode 
if [ $1"x" == "dx" ]; then 
    set -x 
fi 

#Check if log folder exist 
if [ ! -d ~/log ]; then 
    mkdir ~/log
    fi

# Load enviremnet file 
. ~/etc/n8n.cfg

#docker run -it --rm --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n &

#Cleanup docker images 
docker container prune -f

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

#Move current log
DT=`date +%Y%m%d_%H%M`
mv ~/log/n8n_docker.log ~/log/n8n_docker.${DT}.log 

nohup docker run -it --rm \
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
    -e N8N_LOG_OUTPUT=console,file \
    -e N8N_LOG_LEVEL=debug \
    -e N8N_LOG_FILE_LOCATION=/root/log/n8n.log \
    -e N8N_LOG_FILE_SIZE_MAX=50 \
    -e N8N_LOG_FILE_MAXCOUNT=60 \
    -e N8N_SMTP_SSL=true \
    -e N8N_DEFAULT_BINARY_DATA_MODE=filesystem \
    docker.n8n.io/n8nio/n8n > $HOME/log/n8n_docker.log 2>&1 &

echo "Docker started"
exit
#END 

#notes
# https://docs.n8n.io/hosting/logging-monitoring/logging/#setup
# Log level
#silent: outputs nothing at all
#error: outputs only errors and nothing else
#warn: outputs errors and warning messages
#info: contains useful information about progress
#debug: the most verbose output. n8n outputs a lot of information to help you debug issues.