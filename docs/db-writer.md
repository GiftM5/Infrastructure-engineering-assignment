---

# Server: Database Writer (Kafka Consumer)

---

## A. Base Configuration

```bash
# OS assumed: Ubuntu 22.04
sudo apt update && sudo apt upgrade -y

# Create deploy user
sudo adduser deploy
sudo usermod -aG sudo deploy

# App directories
sudo mkdir -p /opt/db-writer /var/log/db-writer
sudo chown -R deploy:deploy /opt/db-writer /var/log/db-writer
sudo chmod 750 /opt/db-writer

# Firewall (internal network)
sudo ufw allow 3306/tcp  # MySQL
sudo ufw allow 9092/tcp  # Kafka
sudo ufw allow 22/tcp    # SSH
sudo ufw enable

# System optimization
echo 'deploy soft nofile 32768' | sudo tee -a /etc/security/limits.conf
echo 'deploy hard nofile 65535' | sudo tee -a /etc/security/limits.conf
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=8192
```

---

## B. Service Installation

```bash
# PHP + required extensions
sudo apt install -y php-cli php-dev php-mysql php-redis php-curl composer git curl wget

# PHP-FPM for long-running consumers
sudo apt install -y php-fpm
cat | sudo tee /etc/php/8.1/fpm/pool.d/db-writer.conf << 'EOF'
[db-writer]
user = deploy
group = deploy
listen = /run/php/db-writer.sock
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 1000
memory_limit = 512M
request_terminate_timeout = 300s
EOF

sudo systemctl restart php8.1-fpm

# Kafka PHP client
sudo apt install -y librdkafka-dev
sudo pecl install rdkafka
echo 'extension=rdkafka.so' | sudo tee -a /etc/php/8.1/cli/php.ini
```

---

## C. Consumer Configuration

**`/opt/db-writer/config/consumer.php`**

```php
<?php
return [
    'kafka' => [
        'broker' => 'kafka:9092',
        'group_id' => 'db_writers',
        'topic' => 'user.signup',
        'auto_offset_reset' => 'earliest',
        'enable_auto_commit' => false,
        'session_timeout_ms' => 30000,
    ],
    'database' => [
        'driver' => 'mysql',
        'host' => 'database',
        'port' => 3306,
        'database' => 'cashit',
        'username' => 'app_user',
        'password' => 'secure_password',
        'options' => [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4",
        ],
    ],
    'processing' => [
        'batch_size' => 50,
        'poll_timeout_ms' => 1000,
        'max_retries' => 3,
        'retry_delay_ms' => 1000,
    ],
    'logging' => [
        'path' => '/var/log/db-writer/consumer.log',
        'level' => 'debug',
    ]
];
?>
```

---

## D. Database Schema

```sql
-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Purchases table
CREATE TABLE purchases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Processed messages table
CREATE TABLE processed_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message_id VARCHAR(255) UNIQUE NOT NULL,
    topic VARCHAR(100),
    partition INT,
    offset BIGINT,
    payload JSON,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dead-letter queue
CREATE TABLE dead_letter_queue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message_id VARCHAR(255),
    topic VARCHAR(100),
    payload LONGTEXT,
    error_message TEXT,
    retries INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## E. Security Configuration

```sql
-- DB Writer user with limited permissions
CREATE USER 'app_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT, INSERT, UPDATE ON cashit.users TO 'app_user'@'%';
GRANT INSERT, UPDATE ON cashit.purchases TO 'app_user'@'%';
GRANT SELECT, INSERT ON cashit.processed_messages TO 'app_user'@'%';
GRANT SELECT, INSERT ON cashit.dead_letter_queue TO 'app_user'@'%';
FLUSH PRIVILEGES;
```

*Environment file:* `/opt/db-writer/.env`

```bash
DB_HOST=database
DB_PORT=3306
DB_USER=app_user
DB_PASS=secure_password
DB_NAME=cashit
KAFKA_BROKER=kafka:9092
KAFKA_GROUP=db_writers
CONSUMER_LOG_LEVEL=debug
```

---

## F. Verification & Monitoring

```bash
# Check consumer process
ps aux | grep run-consumer.php

# Check processed messages
mysql -u app_user -p cashit -e "SELECT COUNT(*) FROM processed_messages;"

# Check dead-letter queue
mysql -u app_user -p cashit -e "SELECT COUNT(*) FROM dead_letter_queue;"
```

**Consumer lag monitoring:**

```bash
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers --describe
```

---

## G. Failure Handling

* **Consumer retry:** 3x with exponential backoff.
* **DLQ:** Failed messages saved to `dead_letter_queue`.
* **Idempotency:** `processed_messages` table prevents duplicates.
* **Database failures:** Transactions + rollback prevent partial writes.
* **Kafka Broker down:** Consumer retries connection until broker is available.

---

## H. Scaling Strategy

* Run multiple consumer instances using `supervisor` or systemd.
* Partition Kafka topic to distribute workload.
* Use connection pooling to database.
* Batch inserts to reduce load.
* Monitor consumer lag and scale horizontally.

---
