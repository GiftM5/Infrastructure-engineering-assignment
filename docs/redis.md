---

# Redis Quick Setup & Verification

## 1. Install & Start

```bash
# Install Redis
apt update && apt install redis-server -y

# Apply config & restart
cp configs/redis/redis.conf /etc/redis/redis.conf
systemctl restart redis

# Test connection
redis-cli ping   # Should return: PONG
```

---

## 2. System Setup & Security

```bash
# Create redis user & directories
useradd -r -s /bin/false redis
mkdir -p /var/lib/redis /var/log/redis
chown -R redis:redis /var/lib/redis /var/log/redis
chmod 750 /var/lib/redis

# Firewall (adjust subnet for production)
ufw allow 6379/tcp   # Redis
ufw allow 26379/tcp  # Sentinel (if HA)
ufw allow 22/tcp     # SSH
ufw enable

# Fail2ban basic
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

---

## 3. Redis Configuration Essentials (`redis.conf`)

```ini
# Network & security
bind 127.0.0.1          # + internal network IP if needed
protected-mode yes
requirepass your_secure_password
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_DISABLED"

# Persistence
appendonly yes
appendfsync everysec
save 900 1
save 300 10
maxmemory 256mb
maxmemory-policy allkeys-lru

# Logging & performance
logfile /var/log/redis/redis-server.log
tcp-backlog 511
tcp-keepalive 300
```

---

## 4. Verification / Health Check

```bash
# Connectivity
redis-cli ping      # PONG
redis-cli INFO memory
redis-cli INFO clients
redis-cli INFO persistence
redis-cli DBSIZE    # Number of keys

# Test write & read
redis-cli SET test_key "hello"
redis-cli GET test_key  # Should return: hello
```

---

## 5. Backup & Recovery

```bash
# Backup (BGSAVE)
redis-cli BGSAVE
cp /var/lib/redis/dump.rdb /backups/redis/$(date +%Y%m%d).rdb

# Restore
systemctl stop redis
cp /backups/redis/dump_latest.rdb /var/lib/redis/dump.rdb
chown redis:redis /var/lib/redis/dump.rdb
systemctl start redis
```

---

## 6. Monitoring

```bash
# Real-time operations
redis-cli MONITOR

# Connected clients & slow commands
redis-cli CLIENT LIST
redis-cli SLOWLOG GET 10

# Memory & keyspace
redis-cli INFO memory
redis-cli INFO keyspace
```

