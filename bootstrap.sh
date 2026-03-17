#shebang for bash
#!/bin/bash

#exit immedietly if any commands fails
set -e

#define new username
USERNAME="devopsuser"

#define variables
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

#Validate environment
echo "Validating environment..."
if[-f /etc/os-release]; then
    . /etc/os-release
    if[["$ID"!="ubuntu"]]; then
        echo "This script supports only Ubuntu"
        exit 1
    fi
else
    echo "Cannot detect operating system."
    exit 1
fi

#check the Internet connection
if !ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "No internet connect detected."
    exit 1
fi

#Check for the required files
for file in "$PROJECT_DIR/app/Dockerfile" "$PROJECT_DIR/app/index.html" "$PROJECT_DIR/nginx/default.conf"; do
    if [! -f "$file"]; then
        echo "Required file missing: $file"
        exit 1
    fi
done

#Check the port 8080 availability
if sudo ss -tulpn | grep -q ":8080 "; then
    echo "Port 8080 is already in use."
    exit 1
fi

#Update system packages
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

#Install required packages
echo "Installing required packages..."
sudo apt-get install -y docker.io nginx ufw htop curl

#Create a new user with validation
if id "USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists"
else
    echo "Creating user $USERNAME..."
    sudo adduser --disabled-password --gecos "" "$USERNAME"
    sudo usermod -aG sudo "$USERNAME"
fi

#Enable Docker
echo "Enabling Docker..."
sudo systemctl enable docker
systemctl start docker
sudo usermod -aG docker "$USERNAME"

#Check Docker status
if !sudo systemctl is-active --quiet docker; then
    echo "Docker failed to start."
    exit 1
fi

#Configure firewall
echo "Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

#enable Nginx
echo "Enabling Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

#check Nginx status
if !sudo systemctl is-active --quiet nginx; then
    echo "Nginx failed to start."
    exit 1
fi

#build docker image
echo "Building Docker image..."
cd "$PROJECT_DIR/app"
sudo docker build -t bootstrap-app .

#remove old docker image
echo "Removing old container if exists..."
sudo docker rm -f bootstrap-app-container 2>dev/null || true

#run docker container
echo "Running Docker container..."
sudo docker run -d --name bootstrap-app-container -p 8080:80 bootstrap-app

#configure Nginx reverse proxy
echo "Configuring Nginx reverse proxy..."
echo cp "$PROJECT_DIR/nginx/default.conf" /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl reload nginx

#Checks local app and Nginx reverse proxy
echo "Checking local app..."
if ! curl -f http://127.0.0.1:8080 >/dev/null; then
    echo "Application health check failed on port 8080."
    exit 1
fi

echo "Checking Nginx reverse proxy..."
if ! curl -f http://127.0.0.1 >/dev/null; then
    echo "Nginx reverse proxy check failed on port 80."
    exit 1
fi

echo "Bootstrap completed successfully."