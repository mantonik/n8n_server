#!/bin/bash 
# 12/13/24 add prune command
# 12/13/24 MA add log location, and rotate log on start 
# 3/1/2025 MA remove execution saved data to reduce storage
#
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
mv ~/log/n8n.log ~/log/n8n.${DT}.log 
gzip ~/log/n8n.${DT}.log

# remove log files older than 30 days from
find ~/log -name "n8n*.log.gz" -mtime +10 -exec rm {} \; 
find ~/log -name "n8n*.log" -mtime +10 -exec rm {} \; 

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
    -e N8N_LOG_LEVEL=info \
    -e N8N_LOG_FILE_SIZE_MAX=50 \
    -e N8N_LOG_FILE_MAXCOUNT=60 \
    -e N8N_SMTP_SSL=true \
    -e N8N_DEFAULT_BINARY_DATA_MODE=filesystem \
    -e EXECUTIONS_DATA_SAVE_ON_SUCCESS=none \
    -e EXECUTIONS_DATA_SAVE_ON_ERROR=all \
    -e EXECUTIONS_DATA_SAVE_ON_PROGRESS=true \
    -e EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true \
    -e EXECUTIONS_DATA_PRUNE=true \
    -e EXECUTIONS_DATA_MAX_AGE=24 \
    docker.n8n.io/n8nio/n8n > $HOME/log/n8n.log 2>&1 &

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

    #-e N8N_LOG_FILE_LOCATION=/root/log/n8n.log \