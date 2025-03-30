#!/bin/bash
#Cleanup repository
dnf clean all 
dnf update

#Install docker 
# install nginx

yum install -y docker nginx

#Copy nginx config file 
cp ../server-config/etc/nginx/nginx.conf /etc/nginx/nginx.conf

#Start services 
service nginx start 

service docker start

#Create n8n_data
docker volume create n8n_data

ls -lrt /etc/nginx/nginx.conf
exit
