#!/bin/bash
echo "================================="
echo "= GNTL Pool Installation Script ="
echo "================================="
echo
echo "We're assuming that this is a clean install (green-field).  If not, please exit in the next 15 seconds..."
echo
sleep 15
echo "Continuing install..."
echo
echo "----------------------------------------------------------------------------------------------------"
echo "Installation - STARTED"
echo "----------------------------------------------------------------------------------------------------"
if [[ `whoami` == "root" ]]; then
    echo
    echo "You ran me as root!  Do not run me as root!"
    echo
    exit 1
fi
echo "----------------------------------------------------------------------------------------------------"
echo "Installing Updates..."
echo "----------------------------------------------------------------------------------------------------"
sudo apt update
DEBIAN_FRONTEND=noninteractive sudo --preserve-env=DEBIAN_FRONTEND apt -y upgrade
cd ~
echo "----------------------------------------------------------------------------------------------------"
echo "Installing Dependancies..."
echo "----------------------------------------------------------------------------------------------------"
sudo apt install build-essential git make nano libssl-dev libboost-all-dev libsodium-dev -y
echo "----------------------------------------------------------------------------------------------------"
echo "Installing NodeJS..."
echo "----------------------------------------------------------------------------------------------------"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
source ~/.nvm/nvm.sh
nvm install v20.14.0
echo "----------------------------------------------------------------------------------------------------"
echo "Cloning Pool..."
echo "----------------------------------------------------------------------------------------------------"
git clone https://github.com/The-GNTL-Project/cryptonote-nodejs-pool pool
echo "----------------------------------------------------------------------------------------------------"
echo "Installing Pool..."
echo "----------------------------------------------------------------------------------------------------"
cd pool
npm update
cd ~
echo "----------------------------------------------------------------------------------------------------"
echo "Installing Redis Server..."
echo "----------------------------------------------------------------------------------------------------"
sudo apt install redis-server -y
sudo cp ~/pool/deployment/rc.local /etc/
sudo chmod +x /etc/rc.local
sudo sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
sudo systemctl enable redis-server
echo "----------------------------------------------------------------------------------------------------"
echo "Installing Caddy..."
echo "----------------------------------------------------------------------------------------------------"
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
sudo chown -R gntlpool:www-data /home/gntlpool/
sudo cp ~/pool/deployment/Caddyfile /etc/caddy/Caddyfile
echo "----------------------------------------------------------------------------------------------------"
echo "Configuring Logrotate..."
echo "----------------------------------------------------------------------------------------------------"
sudo cp ~/pool/deployment/gntl-logs /etc/logrotate.d/gntl-logs
echo "----------------------------------------------------------------------------------------------------"
echo "Installing Node Process Manager..."
echo "----------------------------------------------------------------------------------------------------"
npm install -g pm2
pm2 update
pm2 install pm2-logrotate
pm2 set pm2-logrotate:retain 30
source ~/.bashrc
echo
echo "----------------------------------------------------------------------------------------------------"
echo "Installation - COMPLETE"
echo "----------------------------------------------------------------------------------------------------"
