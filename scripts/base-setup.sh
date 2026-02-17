#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Create a new user
sudo adduser deploy --gecos "" --disabled-password
echo "deploy:password" | sudo chpasswd
sudo usermod -aG sudo deploy

# SSH hardening
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw enable

# Set timezone (default: UTC, change as needed)
sudo timedatectl set-timezone UTC

# Setup swap
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Enable Fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
