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
\cp -rf ${HOME}/bin/n8n_server/etc ${HOME}/
$HOME/bin/n8n_server/bin/start_n8n.sh
sleep 5
curl -vv http://localhost:5678/
echo ""

Run this only one time
echo ""
echo "rename ~/etc/n8n.cfg.sample to ~/etc/n8n.cfg "
echo "Update ~/etc/n8n.cfg file "

#Update configuration file for nginx
# if you already have nginx installed then you need to review configurationi file and update as needed.
cp  ~/bin/n8n_server/server-config/etc/nginx/nginx.conf /etc/nginx/

