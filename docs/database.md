---

# Server: Database Server

---

## A. Base Configuration

```bash
# OS assumed: Ubuntu 22.04 LTS
sudo apt update && sudo apt upgrade -y

# Create deploy user
sudo adduser deploy
sudo usermod -aG sudo deploy

# SSH hardening
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no, PasswordAuthentication no
sudo systemctl restart ssh

# Firewall rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 3306/tcp # MySQL (internal network)
sudo ufw enable

# Timezone
sudo timedatectl set-timezone UTC

# Swap setup
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Install Fail2Ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

---

## B. Service Installation

```bash
# Install MySQL 8.0
sudo apt install mysql-server -y
sudo systemctl enable mysql
sudo systemctl start mysql
```

---

## C. Configuration Files

**`/etc/mysql/mysql.conf.d/mysqld.cnf`**

```ini
[mysqld]
bind-address = 0.0.0.0
port = 3306
default-storage-engine = InnoDB
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
innodb_buffer_pool_size = 1G
innodb_file_per_table = 1
max_connections = 200
```

**Explanation:**

* `bind-address=0.0.0.0` → allows connections from internal network/Docker network.
* `innodb_buffer_pool_size=1G` → tuned for 4GB RAM server.
* `utf8mb4` → full Unicode support.
* `max_connections=200` → enough for app + consumers.

---

## D. Database & User Setup

```sql
-- Create database
CREATE DATABASE cashit CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Users table
CREATE TABLE cashit.users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Purchases table
CREATE TABLE cashit.purchases (
  id INT AUTO_INCREMENT PRIMARY KEY,
  purchase_id VARCHAR(255) UNIQUE NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  amount DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES cashit.users(user_id)
);

-- Processed messages table (Kafka idempotency)
CREATE TABLE cashit.processed_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  message_id VARCHAR(255) UNIQUE NOT NULL,
  topic VARCHAR(100) NOT NULL,
  partition INT NOT NULL,
  offset BIGINT NOT NULL,
  payload JSON,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dead-letter queue
CREATE TABLE cashit.dead_letter_queue (
  id INT AUTO_INCREMENT PRIMARY KEY,
  message_id VARCHAR(255) NOT NULL,
  topic VARCHAR(100) NOT NULL,
  payload LONGTEXT NOT NULL,
  error_message TEXT NOT NULL,
  retries INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Application user
CREATE USER 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT SELECT, INSERT, UPDATE ON cashit.* TO 'app_user'@'%';

-- Analytics user (read-only)
CREATE USER 'analytics'@'%' IDENTIFIED BY 'analytics_password';
GRANT SELECT ON cashit.* TO 'analytics'@'%';

-- Backup user
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'backup_password';
GRANT SELECT, LOCK TABLES, SHOW VIEW ON cashit.* TO 'backup_user'@'localhost';

FLUSH PRIVILEGES;
```

---

## E. Security Configuration

* Open ports: `3306` (internal network only).
* Closed ports: all others.
* Service binding: `0.0.0.0` for Docker internal network, not public internet.
* Strong passwords for all users.
* Optional: enable SSL/TLS if required.

---

## F. Performance Tuning

```bash
# File descriptors
echo 'mysql soft nofile 65535' >> /etc/security/limits.conf
echo 'mysql hard nofile 65535' >> /etc/security/limits.conf

# Kernel tuning
sudo sysctl -w vm.swappiness=10
sudo sysctl -w net.core.somaxconn=8192
```

---

## G. Verification Steps

```bash
# Check MySQL service
systemctl status mysql

# Test connectivity
mysql -u app_user -p -e "SHOW DATABASES;"

# Verify tables
mysql -u app_user -p cashit -e "SHOW TABLES;"

# Simulate failure
sudo systemctl stop mysql
# Observe Kafka consumers / DB writers retry or DLQ triggers
sudo systemctl start mysql

# Check logs
tail -f /var/log/mysql/error.log
```


