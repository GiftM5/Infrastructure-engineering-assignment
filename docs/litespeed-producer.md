# LiteSpeed Producer Web Server

## ⚡ Quick Start

```bash
# 1. Run base setup and install web server
bash scripts/base-setup.sh
bash scripts/install-web.sh

# 2. Apply web server configuration
sudo cp configs/php/php.ini /etc/php/*/cli/php.ini
sudo systemctl reload nginx

# 3. Verify web server
curl http://localhost
```

**Configs:** [nginx.conf](../configs/nginx/nginx.conf), [php.ini](../configs/php/php.ini)
**Setup:** [base-setup.sh](../scripts/base-setup.sh), [install-web.sh](../scripts/install-web.sh)

**Responsibilities:**
- Accept and process HTTP requests from clients
- Generate Kafka events for backend processing
- Store session data in Redis
- Serve dynamic PHP content
- Scale horizontally behind load balancer
sudo systemctl restart ssh
```

### Firewall Configuration
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 7080/tcp
sudo ufw enable
```

### Timezone Configuration
```bash
sudo timedatectl set-timezone UTC
```

### Swap Setup
```bash
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo bash -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
```

### Fail2ban Installation
```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## B. Service Installation

### Install LiteSpeed
```bash
sudo bash -c 'echo "deb [trusted=yes] http://repo.litespeedtech.com/debian jammy main" > /etc/apt/sources.list.d/lst_debian_repo.list'
sudo apt update
sudo apt install openlitespeed -y
sudo systemctl enable lsws
```

### Install PHP 8.1 with Extensions
```bash
sudo apt install -y lsphp81 lsphp81-curl lsphp81-json lsphp81-mysql lsphp81-redis
sudo apt install -y librdkafka-dev
pecl install rdkafka
```

---

## C. Configuration Files

**PHP Configuration:** `/usr/local/lsws/lsphp81/etc/php/8.1/litespeed/php.ini`

```ini
session.save_handler = redis
session.save_path = "tcp://redis:6379/0"
memory_limit = 512M
post_max_size = 100M
upload_max_filesize = 100M
extension = redis
extension = pdo
extension = pdo_mysql
date.timezone = UTC
opcache.enable = 1
opcache.memory_consumption = 128
```

**Kafka Configuration:** `/var/www/html/config/kafka-producer.php`

```php
<?php
return [
    'brokers' => 'kafka:9092',
    'acks' => 'all',
    'retries' => 3,
    'compression_type' => 'snappy',
];
?>
```

---

## D. Security Configuration

**Firewall Rules:**
- Open: `2222/tcp` (SSH), `8080/tcp` (HTTP), `7080/tcp` (Admin)
- Closed: All others

**Disable Dangerous Functions:**
```ini
disable_functions = exec,passthru,shell_exec,system
allow_url_fopen = Off
```

---

## E. Performance Tuning

**Sysctl Settings:**
```bash
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
fs.file-max = 2097152
```

**File Descriptors:**
```bash
sudo bash -c 'echo "* soft nofile 65536" >> /etc/security/limits.conf'
```

---

## F. Verification Steps

```bash
# Check status
sudo systemctl status lsws

# Test configuration
/usr/local/lsws/bin/lshttpd -t

# Check ports
sudo netstat -tulnp | grep lsws

# Test Redis
/usr/local/lsws/lsphp81/bin/php -r "\$r = new Redis(); \$r->connect('redis', 6379); echo \$r->ping();"

# View logs
sudo tail -f /usr/local/lsws/logs/error.log
```

---

## Summary

LiteSpeed Producer servers handle incoming HTTP requests and produce Kafka events. They are stateless, use Redis for sessions, and scale horizontally behind the load balancer.
