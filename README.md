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
