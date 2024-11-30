# n8n_server
Repository to start and manage the n8n custom server 

######################
# Setup server 
# run application as user who will start docker for n8n ( it was develop as root user for now )
# some parts will be runned as root user but file system will be under opc or user of your choise 

cd ~/bin 
rm -rf n8n_server
wget https://github.com/mantonik/n8n_server/archive/refs/heads/main.zip
unzip main.zip 
rm -f main.zip
mv n8n_server-main n8n_server
