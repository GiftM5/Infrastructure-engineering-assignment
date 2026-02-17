# Load Balancer Server – srv-lb-01
Private IP: 10.0.0.10
Role: Public traffic entry point

---

## A. Base Configuration

### OS
Ubuntu Server 22.04 LTS

### System Update
sudo apt update && sudo apt upgrade -y

### User Creation
sudo adduser deploy
sudo usermod -aG sudo deploy

### SSH Hardening
Edit /etc/ssh/sshd_config:
PermitRootLogin no
PasswordAuthentication no

Restart:
sudo systemctl restart ssh

### Firewall Rules
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

Only ports 80/443 exposed publicly.

### Fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban

### Timezone
sudo timedatectl set-timezone Africa/Johannesburg

---

## B. Service Installation

HAProxy Version 2.4.x

sudo apt install haproxy -y
sudo systemctl enable haproxy

---

## C. Configuration File

File: /etc/haproxy/haproxy.cfg

global
    log /dev/log local0
    maxconn 50000
    daemon

defaults
    mode http
    timeout connect 5s
    timeout client 50s
    timeout server 50s

frontend http_front
    bind *:80
    default_backend web_servers

backend web_servers
    balance roundrobin
    option httpchk
    server web1 10.0.0.20:80 check
    server web2 10.0.0.21:80 check
    server web3 10.0.0.22:80 check

Health checks ensure failed nodes are removed automatically.

---

## D. Security Design

Public Ports:
- 80 (HTTP)
- 443 (HTTPS)

Closed:
- 9092
- 6379
- 5432

Only internal private network allowed to backend servers.

---

## E. Performance Tuning

Edit /etc/sysctl.conf:

net.core.somaxconn = 65535
vm.swappiness = 10

Apply:
sudo sysctl -p

---

## F. Verification

systemctl status haproxy
ss -tulnp
curl http://10.0.0.10

Simulate failure:
sudo systemctl stop haproxy
