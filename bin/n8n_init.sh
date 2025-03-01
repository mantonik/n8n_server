#!/bin/bash
#Install docker 
# install nginx

yum install -y docker nginx

#Copy nginx config file 
cp ../server-config/etc/nginx/nginx.conf /etc/nginx/nginx.conf

ls -lrt - /etc/nginx/nginx.conf
exit
