#!/bin/bash
#Cleanup repository
dnf clean all 
dnf update

#Install docker 
# install nginx

yum install -y docker nginx policycoreutils-python-utils

#Generate SSL certificate 
mkdir -p /etc/nginx/ssl

sudo openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=localhost"

  
#Copy nginx config file 
cp ../server-config/etc/nginx/nginx.conf /etc/nginx/nginx.conf

#Start services 
service nginx start 
service docker start

#Enable service on server start
systemctl enable nginx 
systemctl enable docker 


#Create n8n_data
docker volume create n8n_data

ls -lrt /etc/nginx/nginx.conf
exit
