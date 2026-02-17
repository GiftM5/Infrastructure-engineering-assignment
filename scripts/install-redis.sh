#!/bin/bash

# Install Redis
sudo apt install redis-server -y

# Configure Redis to start on boot
sudo systemctl enable redis-server

# Modify Redis configuration for persistence
sudo sed -i 's/# save 900 1/save 900 1/' /etc/redis/redis.conf
sudo sed -i 's/# save 300 10/save 300 10/' /etc/redis/redis.conf
sudo sed -i 's/# save 60 10000/save 60 10000/' /etc/redis/redis.conf

# Restart Redis service
sudo systemctl restart redis-server
