#!/bin/bash

# NexusGreen Server Reset Script
# This script resets the server to a fresh Ubuntu state

set -e

echo "========================================"
echo "NexusGreen Server Reset Script"
echo "========================================"
echo
echo "WARNING: This will completely reset your server!"
echo "This will remove:"
echo "- All Docker containers and images"
echo "- All Docker volumes and networks"
echo "- PostgreSQL and all databases"
echo "- Nginx and all configurations"
echo "- All SSL certificates"
echo "- All application data"
echo
read -p "Are you absolutely sure you want to continue? (type 'RESET' to confirm): " -r
if [[ ! $REPLY == "RESET" ]]; then
    echo "Reset cancelled."
    exit 1
fi

echo
echo "Starting server reset..."

# Stop all services
echo "1. Stopping all services..."
sudo systemctl stop nginx 2>/dev/null || echo "Nginx not running"
sudo systemctl stop postgresql 2>/dev/null || echo "PostgreSQL not running"
sudo systemctl stop apache2 2>/dev/null || echo "Apache not running"
sudo systemctl stop mysql 2>/dev/null || echo "MySQL not running"

# Disable services from auto-starting
echo "2. Disabling services..."
sudo systemctl disable nginx 2>/dev/null || echo "Nginx not installed"
sudo systemctl disable postgresql 2>/dev/null || echo "PostgreSQL not installed"
sudo systemctl disable apache2 2>/dev/null || echo "Apache not installed"
sudo systemctl disable mysql 2>/dev/null || echo "MySQL not installed"

# Stop and remove all Docker containers
echo "3. Cleaning up Docker..."
if command -v docker >/dev/null 2>&1; then
    # Stop all containers
    docker stop $(docker ps -aq) 2>/dev/null || echo "No containers to stop"
    
    # Remove all containers
    docker rm $(docker ps -aq) 2>/dev/null || echo "No containers to remove"
    
    # Remove all images
    docker rmi $(docker images -q) 2>/dev/null || echo "No images to remove"
    
    # Remove all volumes
    docker volume rm $(docker volume ls -q) 2>/dev/null || echo "No volumes to remove"
    
    # Remove all networks
    docker network rm $(docker network ls -q) 2>/dev/null || echo "No custom networks to remove"
    
    # Clean up system
    docker system prune -af --volumes
    
    # Remove Docker completely
    sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-compose-plugin 2>/dev/null || echo "Docker packages not found"
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || echo "Docker CE not found"
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    sudo rm -f /usr/local/bin/docker-compose
fi

# Remove web servers and databases
echo "4. Removing web servers and databases..."
sudo apt-get remove -y nginx nginx-common nginx-core 2>/dev/null || echo "Nginx not installed"
sudo apt-get remove -y apache2 apache2-common 2>/dev/null || echo "Apache not installed"
sudo apt-get remove -y postgresql postgresql-contrib postgresql-client 2>/dev/null || echo "PostgreSQL not installed"
sudo apt-get remove -y mysql-server mysql-client 2>/dev/null || echo "MySQL not installed"
sudo apt-get purge -y nginx nginx-common nginx-core 2>/dev/null || echo "Nginx already purged"
sudo apt-get purge -y postgresql postgresql-contrib postgresql-client 2>/dev/null || echo "PostgreSQL already purged"

# Remove configuration directories
echo "5. Removing configuration directories..."
sudo rm -rf /etc/nginx
sudo rm -rf /etc/postgresql
sudo rm -rf /etc/mysql
sudo rm -rf /var/lib/postgresql
sudo rm -rf /var/lib/mysql
sudo rm -rf /var/www
sudo rm -rf /etc/letsencrypt
sudo rm -rf /var/lib/letsencrypt

# Remove application directories
echo "6. Removing application directories..."
rm -rf ~/NexusGreen
rm -rf ~/nexusgreen
rm -rf ~/app
rm -rf ~/.docker

# Clean up users and groups
echo "7. Cleaning up users and groups..."
sudo deluser postgres 2>/dev/null || echo "postgres user not found"
sudo delgroup postgres 2>/dev/null || echo "postgres group not found"
sudo deluser mysql 2>/dev/null || echo "mysql user not found"
sudo delgroup mysql 2>/dev/null || echo "mysql group not found"
sudo deluser www-data 2>/dev/null || echo "www-data user not found"
sudo delgroup www-data 2>/dev/null || echo "www-data group not found"

# Clean package cache and update
echo "8. Cleaning package system..."
sudo apt-get autoremove -y
sudo apt-get autoclean
sudo apt-get update

# Remove any remaining processes
echo "9. Killing remaining processes..."
sudo pkill -f postgres 2>/dev/null || echo "No postgres processes"
sudo pkill -f nginx 2>/dev/null || echo "No nginx processes"
sudo pkill -f docker 2>/dev/null || echo "No docker processes"

# Clear logs
echo "10. Clearing logs..."
sudo rm -rf /var/log/nginx
sudo rm -rf /var/log/postgresql
sudo rm -rf /var/log/mysql
sudo rm -rf /var/log/docker
sudo rm -rf /var/log/letsencrypt

# Reset firewall to defaults
echo "11. Resetting firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

echo
echo "========================================"
echo "Server Reset Complete!"
echo "========================================"
echo
echo "Your server has been reset to a fresh Ubuntu state."
echo "You can now run the clean production installation script."
echo
echo "System status:"
free -h
df -h
echo
echo "Next step: Run the clean production installation script"