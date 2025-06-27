# n8n_server
Repository to start and manage the n8n custom server 

######################
# Setup server 
run application as user who will start docker for n8n ( it was develop as root user for now )
some parts will be runned as root user but file system will be under opc or user of your choise 

mkdir ~/bin
cd ~/bin 

rm -rf n8n_server
wget https://github.com/mantonik/n8n_server/archive/refs/heads/main.zip
unzip main.zip 
rm -f main.zip
mv n8n_server-main n8n_server

cd ~/bin
rm -rf n8n_server
wget https://github.com/mantonik/n8n_server/archive/refs/heads/cloudflare.zip
unzip cloudflare.zip 
rm -f cloudflare.zip
mv n8n_server-cloudflare n8n_server
chmod 755 ~/bin/n8n_server/bin/*.sh

cd /root/bin/n8n_server/bin


chmod 755 ~/bin/n8n_server/bin/*.sh
crontab ~/bin/n8n_server/cron/root.cron 

# If this is first time run you need to initialize and make base instalation 
# run script 
$HOME/bin/n8n_server/bin/n8n_init.sh

\cp -rf ${HOME}/bin/n8n_server/etc ${HOME}/

#Update nginx and restart 
\cp  ~/bin/n8n_server/server-config/etc/nginx/nginx.conf /etc/nginx/
service nginx restart 

$HOME/bin/n8n_server/bin/start_n8n.sh
sleep 5
curl -vv http://localhost:5678/
echo ""

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Run this only one time, this will create custom n8n.cfg file with parameters required to run application
cp ~/etc/n8n.cfg.sample ~/etc/n8n.cfg

# ---------

#Update configuration file for nginx
# if you already have nginx installed then you need to review configurationi file and update as needed.


# Disable SELInux
setenforce 0
#semanage port -a -t http_port_t -p tcp 5678
#semanage port -l | grep 5678

# Disable firewall ( if you have enabled in your server - if you control secutiry throw network layer you can disable, if not open only what is needed port 80, 443)
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl mask --now firewalld

---
Setup CloudFlare tunnel 


Follow below tutorial to get API key and save a key in file $home/etc/coudflare.cfg file ( copy cloudflare.cfg.sample to cloudflare.cfg and update API key )

Login to 
https://developers.cloudflare.com/fundamentals/api/get-started/create-token/


-----
deploy for nginx application changes


cd ~/bin
rm -rf n8n_server
wget https://github.com/mantonik/n8n_server/archive/refs/heads/cloudflare.zip
unzip cloudflare.zip 
rm -f cloudflare.zip
mv n8n_server-cloudflare n8n_server
chmod 755 ~/bin/n8n_server/bin/*.sh
#copy nginx files 
\cp -r ~/bin/n8n_server/server-config/data/nginx/* /data/nginx
chmod 755 ~/bin/n8n_server/bin/dockerfile/www_php_app/build.sh
chmod 755 ~/bin/n8n_server/bin/dockerfile/nginx_php/*.sh
\cp -r n8n_server/server-config/data/* /data

find /root/bin/n8n_server/bin -name "*.sh" -exec chmod 755 {} \; -print

#Fix file permissions
find /data/docker -type d -exec chmod 755 {} \; -print
find /data/docker -type f -exec chmod 644 {} \; -print

#rebuild webapp
cd /root/bin/n8n_server/bin/dockerfile/wwwapp
./wwwapp-podman.sh clean
./wwwapp-podman.sh build
./wwwapp-podman.sh start
./wwwapp-podman.sh status
./wwwapp-podman.sh restart
curl -v http://localhost:8001/t.html
ls -lrt /data/docker/wwwapp/etc/nginx

ls -la /data/docker/wwwapp/var/www/html/urlcheck/
chmod 755 /data/docker/wwwapp/var/www
ls -la /data/docker/wwwapp/var/www/html/urlcheck/



ll /data/nginx/html/urlcheck/
chmod 755 /data/nginx/html/urlcheck
chmod 644 /data/nginx/html/urlcheck/*

#copy nginx files 
cd /etc/nginx
\cp /root/bin/n8n_server/server-config/etc/nginx/* /etc/nginx/
\cp /root/bin/n8n_server/server-config/etc/nginx/conf.d/urlcheck.conf /etc/nginx/conf.d/
service nginx stop 
service nginx start 


/root/bin/n8n_server/bin/dockerfile/wwwapp/wwwapp-podman.sh start

/root/bin/n8n_server/bin/dockerfile/wwwapp/wwwapp-podman.sh restart


tail -f /var/log/nginx/*

