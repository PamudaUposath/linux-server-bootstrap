#!/bin/bash

set -e

USERNAME="devopsuser"

echo "Starting reset process..."

#Remove Docker container
echo "Removing Docker container..."
sudo docker rm -f bootstrap-app-container 2>/dev/null || true

#Remove Docker image
echo "Removing Docker image..."
sudo docker rmi bootstrap-app 2>/dev/null || true

#Stop and disable Docker
echo "Stopping Docker..."
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl disable docker 2>/dev/null || true
sudo systemctl stop docker.socket 2>/dev/null || true
sudo systemctl disable docker.socket 2>/dev/null || true

#Restore Nginx default site config
echo "Restoring Nginx default configuration..."

sudo tee /etc/nginx/sites-available/default > /dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

#Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

#Reset firewall
echo "Resetting firewall..."
sudo ufw --force reset
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

#User removal
read -p "Do you want to remove user $USERNAME? (y/n): " REMOVE_USER
if [ "$REMOVE_USER" = "y" ]; then
    echo "Removing user $USERNAME..."
    sudo deluser --remove-home "$USERNAME" 2>/dev/null || true
fi

echo "Reset completed successfully."
