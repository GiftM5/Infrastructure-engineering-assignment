#!/bin/bash

# Install LiteSpeed
sudo apt install litespeed -y

# Configure LiteSpeed to start on boot
sudo systemctl enable litespeed

# Set up PHP (if required)
sudo apt install php php-mysql -y

# Restart LiteSpeed service
sudo systemctl restart litespeed
