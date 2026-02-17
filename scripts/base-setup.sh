#!/bin/bash

apt update && apt upgrade -y

adduser deploy --disabled-password --gecos ""
usermod -aG sudo deploy

timedatectl set-timezone Africa/Johannesburg

apt install ufw fail2ban curl wget net-tools -y

ufw allow OpenSSH
ufw enable

systemctl enable fail2ban
