---

# LiteSpeed Consumer Quick Setup & Monitoring

## 1. Base Setup

```bash
# Base system setup
bash scripts/base-setup.sh

# Install web server & PHP
bash scripts/install-web.sh

# Kafka PHP extensions
apt install -y librdkafka-dev
pecl install rdkafka
```

---

## 2. System User & Security

```bash
# Create dedicated user
useradd -m -s /bin/bash -G sudo litespeed
echo 'litespeed ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/litespeed

# Harden SSH
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Firewall
ufw default deny incoming
ufw allow 22/tcp       # SSH
ufw allow 9092/tcp     # Kafka
ufw allow 3306/tcp     # MySQL
ufw enable
```

---

## 3. LiteSpeed & PHP Installation

```bash
# LiteSpeed
wget https://releases.litespeedtech.com/openlitespeed/openlitespeed-1.7.17.tar.gz
tar xzf openlitespeed-1.7.17.tar.gz
cd openlitespeed-1.7.17
./configure --prefix=/usr/local/lsws --enable-php --enable-http2
make && make install

# PHP (8.1)
wget https://www.php.net/distributions/php-8.1.27.tar.gz
tar xzf php-8.1.27.tar.gz
cd php-8.1.27
./configure --prefix=/usr/local/php --with-openssl --with-pdo-mysql --enable-mbstring --with-zlib --with-curl --enable-sockets --with-fpm
make && make install
```

---

## 4. Consumer Setup

```bash
# App directories
mkdir -p /var/www/consumer /var/log/consumer
chown -R nobody:nogroup /var/www/consumer

# Initialize DB (idempotency & DLQ)
php /var/www/consumer/init-consumer.php

# Start consumer
php /var/www/consumer/run-consumer.php
```

**Core Logic:**

* Kafka broker: `kafka:9092`
* Consumer group: `db_writers`
* Idempotency table: `processed_messages`
* Dead-letter queue: `dead_letter_queue`
* Retry: 3x, then DLQ

---

## 5. Health Check (Quick)

```bash
#!/bin/bash
# consumer-health-check.sh

# Check process
pgrep -f 'php.*kafka-consumer.php' && echo "✓ Consumer running"

# Kafka connectivity
timeout 5 php -r "new RdKafka\Producer((new RdKafka\Conf())->set('bootstrap.servers','kafka:9092')); echo '✓ Kafka OK\n';"

# Database connectivity
php -r "new PDO('mysql:host=database;dbname=cashit','app_user','secure_password'); echo '✓ DB OK\n';"
```

---

## 6. Consumer Monitoring

```bash
# Check consumer lag
php /var/www/consumer/check-lag.php

# System performance
watch -n 1 '
echo "CPU & Memory:"
top -bn1 | head -5
echo "Consumer Processes:"
ps aux | grep php | grep -v grep
'
```

---

## 7. Failure Recovery

```bash
# Graceful shutdown
kill -SIGTERM $(pgrep -f 'php.*kafka-consumer.php')

# Retry DLQ
php /var/www/consumer/retry-dlq.php

# Restart consumer
php /var/www/consumer/run-consumer.php
```

---

## 8. Debugging

```bash
# Consumer group status
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers --describe

# Reset offset to earliest (use with caution)
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers --topic user.signup --reset-offsets --to-earliest --execute
```

---
