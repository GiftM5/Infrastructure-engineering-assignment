---

# Nginx Load Balancer Quick Setup & Monitoring

## 1. Base Setup

```bash
# Base system and web stack
bash scripts/base-setup.sh
bash scripts/install-web.sh

# Install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx
```

---

## 2. System Security & Firewall

```bash
# Harden SSH
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp   # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw enable

# Fail2ban for SSH
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 3. SSL Certificates

```bash
# Let's Encrypt (production)
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Self-signed (testing)
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/key.pem \
  -out /etc/nginx/ssl/cert.pem
```

---

## 4. Nginx Configuration

### Main Nginx Config

```bash
sudo cp configs/nginx/nginx.conf /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl reload nginx
```

### Backend Upstreams

```nginx
upstream litespeed_backend {
    least_conn;
    server litespeed1:8080 max_fails=3 fail_timeout=30s;
    server litespeed2:8080 max_fails=3 fail_timeout=30s;
    server litespeed3:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

upstream litespeed_backend_sticky {
    hash $cookie_SERVERID consistent;
    server litespeed1:8080;
    server litespeed2:8080;
    server litespeed3:8080;
}
```

### Key Performance & Security

```nginx
worker_processes auto;
worker_connections 2048;
keepalive_timeout 65;
client_max_body_size 100M;
gzip on; gzip_comp_level 6;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_session_cache shared:SSL:10m;

add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
```

---

## 5. System Performance Tuning

```bash
# sysctl tuning
sudo bash -c 'cat >> /etc/sysctl.conf <<EOF
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
fs.file-max = 2097152
EOF'
sudo sysctl -p

# File descriptor limits
sudo bash -c 'echo "* soft nofile 65536" >> /etc/security/limits.conf'
sudo bash -c 'echo "* hard nofile 65536" >> /etc/security/limits.conf'
```

---

## 6. Verification

```bash
# Check service
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# Check listening ports
sudo netstat -tulnp | grep nginx

# Test backend connectivity
curl -I http://localhost:8080
curl -I https://localhost:443
curl http://localhost:8080/health
```

---

## 7. Monitoring

```bash
# Real-time connections
watch -n 1 'netstat -an | grep ESTABLISHED | wc -l'

# Nginx status page
curl http://127.0.0.1:8080/nginx_status

# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## 8. Failover Testing

```bash
# Stop one backend
docker stop litespeed1

# Verify traffic routed to others
curl http://localhost/

# Restart backend
docker start litespeed1
```

---

## 9. SSL Renewal

```bash
# Dry-run renewal
sudo certbot renew --dry-run

# Enable automatic renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---