# Failure Scenarios and Disaster Recovery

## ⚡ Recovery Commands

```bash
# Service Health & Restart
sudo systemctl status nginx
sudo systemctl restart nginx

sudo systemctl status mysql
sudo systemctl restart mysql

sudo systemctl status kafka
sudo systemctl restart kafka

sudo systemctl status redis
sudo systemctl restart redis

# Backup & Restore
bash scripts/backup-mysql-database.sh
bash scripts/backup-redis.sh
```

**Mitigation Strategies:**
1. **High Availability** - Deploy redundant load balancers with automatic failover
2. **Database Replication** - MySQL master-slave replication
3. **Kafka Replication** - Topic replication factor ≥ 2
4. **Redis Persistence** - RDB snapshots (BGSAVE)
5. **Automated Backups** - Daily backups, 7-day retention

**Setup & Backup Scripts:**
- [setup-mysql-database.sh](../scripts/setup-mysql-database.sh)
- [setup-kafka-topics.sh](../scripts/setup-kafka-topics.sh)
- [backup-mysql-database.sh](../scripts/backup-mysql-database.sh)
- [backup-redis.sh](../scripts/backup-redis.sh)

---

## 2. Kafka Broker Failure

### Scenario
The Kafka broker becomes unavailable, stopping message processing.

### Impact
- New messages cannot be produced
- Consumers cannot pull messages
- Events are buffered on producer side
- Existing messages in Kafka remain safe
- RTO: 5-10 minutes
- RPO: No data loss (if properly configured)

### Mitigation Strategies

**1. Multi-Broker Setup (Production)**
```bash
# Configure replication factor
/opt/kafka/bin/kafka-topics.sh \
  --create \
  --bootstrap-server kafka:9092 \
  --topic user.signup \
  --partitions 3 \
  --replication-factor 3
```

**2. Persistence Configuration**
```properties
# In server.properties
log.retention.hours=168
log.segment.bytes=1073741824
```

**3. Consumer Offset Management**
```bash
# Store offsets in Kafka (not Zookeeper)
offsets.topic.replication.factor=3
```

### Recovery Procedure
```bash
# 1. Check Kafka broker status
ps aux | grep kafka

# 2. Check Zookeeper
/opt/kafka/bin/zookeeper-shell.sh localhost:2181

# 3. Restart broker
sudo systemctl restart kafka

# 4. Verify broker is in cluster
/opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server kafka:9092

# 5. Check consumer group status
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 --list
```

---

## 3. Redis Failure

### Scenario
Redis server crashes or becomes unreachable.

### Impact
- Session data is lost
- All users are logged out
- New sessions can be created but old sessions lost
- Performance degradation if cache was heavily used
- RTO: 2-5 minutes
- RPO: Depends on persistence configuration (AOF or RDB)

### Mitigation Strategies

**1. Redis Persistence**
```bash
# Enable AOF for durability
appendonly yes
appendfsync everysec

# Enable RDB snapshots
save 900 1
save 300 10
```

**2. Redis Replication (Sentinel)**
```bash
# Configure master-slave replication
replicaof localhost 6379

# Use Redis Sentinel for automatic failover
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 180000
```

**3. Backup Strategy**
```bash
# Automated daily backups
0 2 * * * cp /var/lib/redis/dump.rdb /backups/redis-$(date +\%Y\%m\%d).rdb
```

### Recovery Procedure
```bash
# 1. Check Redis status
redis-cli ping

# 2. Check persistence
redis-cli BGSAVE
redis-cli LASTSAVE

# 3. Restart Redis
sudo systemctl restart redis-server

# 4. Verify data
redis-cli INFO persistence

# 5. If needed, restore from backup
redis-cli shutdown
cp /backups/redis-20240217.rdb /var/lib/redis/dump.rdb
sudo systemctl start redis-server
```

---

## 4. Database Server Failure

### Scenario
MySQL database becomes unavailable.

### Impact
- Application cannot read or write data
- All data-dependent operations fail
- Sessions may still work (stored in Redis)
- RTO: 10-30 minutes
- RPO: Last backup time

### Mitigation Strategies

**1. Database Replication**
```sql
-- Configure master-slave replication
-- Master
CHANGE MASTER TO MASTER_HOST='slave_ip', MASTER_USER='replication', MASTER_PASSWORD='password';
START SLAVE;
```

**2. Automated Backups**
```bash
# Daily incremental backups
0 2 * * * /usr/bin/mysqldump -u backup_user -ppassword --all-databases | gzip > /backups/mysql-$(date +\%Y\%m\%d).sql.gz

# Binary log backup (for point-in-time recovery)
0 3 * * * mysqlbinlog /var/lib/mysql/mysql-bin.* | gzip > /backups/binlog-$(date +\%Y\%m\%d).sql.gz
```

**3. Point-in-Time Recovery**
```bash
# Restore from backup and apply binlogs
mysql -u root -p < full-backup.sql
mysqlbinlog binlog-20240217.sql | mysql -u root -p
```

### Recovery Procedure
```bash
# 1. Check database status
sudo systemctl status mysql

# 2. Check error log
sudo tail -f /var/log/mysql/error.log

# 3. Restart database
sudo systemctl restart mysql

# 4. Verify data
mysql -u app_user -p app_password cashit -e "SELECT COUNT(*) FROM users;"

# 5. If corrupted, restore from backup
sudo systemctl stop mysql
cp /backups/mysql-20240216.sql.gz /tmp/
gzip -d /tmp/mysql-20240216.sql.gz
mysql -u root -p < /tmp/mysql-20240216.sql
sudo systemctl start mysql
```

---

## 5. LiteSpeed Web Server Failure

### Scenario
One or more LiteSpeed web servers crash or become unreachable.

### Impact
- Load balancer removes failed server from pool
- Traffic redistributes to healthy servers
- No data loss
- Slight increase in latency for remaining servers
- RTO: Automatic (10-30 seconds via health checks)
- RPO: No data loss

### Mitigation Strategies

**1. Health Checks**
```nginx
# Load balancer periodically checks:
location /health {
    access_log off;
    return 200 "healthy\n";
}
```

**2. Graceful Degradation**
```bash
# Load balancer removes unhealthy servers
# Remaining servers handle increased load
# Queue requests if needed
```

**3. Monitoring and Alerts**
```bash
# Monitor server health
watch -n 5 'curl -s http://litespeed1:8080/health; echo "---"; curl -s http://litespeed2:8080/health; echo "---"; curl -s http://litespeed3:8080/health'
```

### Recovery Procedure
```bash
# 1. SSH into failed server
ssh -p 2222 deploy@litespeed1

# 2. Check LiteSpeed status
sudo systemctl status lsws

# 3. Check error logs
sudo tail -f /usr/local/lsws/logs/error.log

# 4. Restart LiteSpeed
sudo systemctl restart lsws

# 5. Verify health
curl http://localhost:8080/health

# 6. Load balancer automatically adds back to pool
```

---

## 6. Database Writer Consumer Failure

### Scenario
One or more database writer consumers crash or stop processing.

### Impact
- Messages accumulate in Kafka
- Database updates are delayed
- Consumer group rebalancing occurs
- Data is eventually processed when consumer restarts
- RTO: 2-5 minutes
- RPO: No data loss (stored in Kafka)

### Mitigation Strategies

**1. Consumer Group Management**
```bash
# Multiple consumers in same group for load sharing
docker run -e CONSUMER_MODE=true -e CONSUMER_GROUP=db_writers consumer1
docker run -e CONSUMER_MODE=true -e CONSUMER_GROUP=db_writers consumer2

# When one fails, other continues and rebalancing occurs
```

**2. Idempotency**
```sql
-- Database prevents duplicate processing
CREATE TABLE processed_messages (
    message_id VARCHAR(255) UNIQUE,
    topic VARCHAR(100),
    partition INT,
    offset BIGINT
);
```

**3. Dead-Letter Queue**
```bash
# Failed messages sent to DLQ for manual review
/opt/kafka/bin/kafka-topics.sh --create --topic dead-letter-queue --bootstrap-server kafka:9092
```

### Recovery Procedure
```bash
# 1. Check consumer status
docker ps | grep consumer

# 2. View consumer logs
docker logs consumer1

# 3. Check consumer group lag
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers --describe

# 4. Restart consumer
docker restart consumer1

# 5. Verify processing resumes
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers --describe
```

---

## 7. Network Partition

### Scenario
Network split between components (e.g., load balancer isolated from backend).

### Impact
- Requests timeout
- Client connections hang
- Kafka consumers face split-brain issues
- Database transactions may not complete
- RTO: 5-10 minutes
- RPO: Depends on which side continues

### Mitigation Strategies

**1. Network Redundancy**
```bash
# Multiple network paths
# Configure bond0 interface with multiple NICs
# Use LACP (Link Aggregation Control Protocol)
```

**2. Connection Timeouts**
```nginx
# Short timeouts prevent hanging connections
proxy_connect_timeout 10s;
proxy_send_timeout 10s;
proxy_read_timeout 10s;
```

**3. Kafka Quorum**
```bash
# With 3 brokers, 2 can survive network partition
# Ensure min.insync.replicas = 2
# Prevents split-brain writes
```

### Recovery Procedure
```bash
# 1. Identify partition
ping backend-servers
telnet load-balancer:9092

# 2. Check network connectivity
traceroute backend-server
netstat -rn | grep default

# 3. Restore network
# Replace faulty network equipment
# Verify routes

# 4. Restart affected services
sudo systemctl restart kafka
sudo systemctl restart lsws

# 5. Verify cluster state
/opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server kafka:9092
```

---

## 8. Data Corruption

### Scenario
Database tables become corrupted due to crash or hardware failure.

### Impact
- Affected queries fail
- Application errors reported
- RTO: 20-60 minutes
- RPO: Last clean backup

### Mitigation Strategies

**1. Regular Integrity Checks**
```bash
# Daily table checks
0 1 * * * mysqlcheck -u backup_user -p --all-databases
```

**2. Redundant Storage**
```bash
# RAID-1 mirroring on database server
# Protects against single disk failure
```

**3. Immutable Backups**
```bash
# Keep backups on separate storage
0 2 * * * mysqldump -u backup_user -ppassword cashit | gzip | gpg --encrypt > /offline-backups/cashit-$(date +\%Y\%m\%d).sql.gz.gpg
```

### Recovery Procedure
```bash
# 1. Identify corruption
mysqlcheck -u root -p cashit

# 2. Repair if possible
REPAIR TABLE table_name;

# 3. If repair fails, restore from backup
mysql -u root -p cashit < clean-backup.sql
```

---

## 9. DDoS Attack

### Scenario
Large volumetraffic surge from malicious sources.

### Impact
- Service becomes slow or unresponsive
- Legitimate users affected
- Potential data exfiltration risk
- RTO: 5-30 minutes
- RPO: No data loss

### Mitigation Strategies

**1. Rate Limiting**
```nginx
# Nginx rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=100r/s;
limit_req zone=api burst=200 nodelay;
```

**2. DDoS Protection**
```bash
# Use cloud DDoS protection service
# Cloudflare, AWS Shield, Azure DDoS Protection
```

**3. Firewall Rules**
```bash
# Block suspicious traffic
sudo ufw deny from 192.168.1.0/24
sudo ufw status numbered
```

### Recovery Procedure
```bash
# 1. Identify attack source
sudo tail -f /var/log/nginx/access.log | grep "suspicious pattern"

# 2. Implement firewall rules
sudo ufw deny from 10.0.0.0/8

# 3. Enable DDoS protection
# Contact cloud provider DDoS mitigation service

# 4. Monitor traffic
watch -n 1 'netstat -an | grep ESTABLISHED | wc -l'
```

---

## 10. Complete Infrastructure Failure

### Scenario
Multiple critical components fail simultaneously (rare but possible).

### Impact
- Complete service outage
- All users affected
- RTO: 30-60 minutes
- RPO: Last backup (likely significant data loss)

### Mitigation Strategies

**1. Disaster Recovery Plan**
```bash
# Maintain current documentation
# Backup all configs to version control
# Test recovery procedures quarterly
```

**2. Geographic Redundancy**
```bash
# Replicate infrastructure in another region
# Database replication to secondary site
# Regular failover drills
```

**3. Backup Strategy**
```bash
# Daily full backups
# Hourly incremental backups
# Weekly offline backups to external storage
# Test recovery monthly
```

### Recovery Procedure
```bash
# 1. Assess damage
ssh into any remaining server
Check logs for root cause

# 2. Prioritize recovery
1. Database (restore from backup)
2. Kafka (recreate topics if needed)
3. Redis (restore sessions)
4. Load Balancer
5. Web servers

# 3. Execute recovery in order
# Start with most critical components

# 4. Verify end-to-end functionality
curl http://load-balancer/health
mysql -h database -u app_user -p cashit -e "SELECT 1;"
redis-cli ping

# 5. Failover to secondary site if primary unrecoverable
```

---

## Data Loss Prevention

### Backup Strategy
```bash
# Daily full backups at 2 AM UTC
0 2 * * * /scripts/backup-database.sh

# Hourly incremental backups
0 * * * * /scripts/backup-incremental.sh

# Weekly full backup to offline storage
0 3 * * 0 /scripts/backup-offline.sh

# Kafka topic backups
0 1 * * * /opt/kafka/bin/kafka-mirror-maker.sh --consumer.config consumer.properties --producer.config producer.properties --whitelist user.*
```

### Duplicate Write Prevention
```sql
-- Idempotency via unique constraints
CREATE TABLE processed_messages (
    message_id VARCHAR(255) UNIQUE NOT NULL,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Prevents reprocessing of same message
INSERT INTO processed_messages (message_id) VALUES (?) ON DUPLICATE KEY UPDATE processed_at=NOW();
```

---

## Summary

This infrastructure is designed with multiple layers of fault tolerance:
- **Load Balancer Redundancy:** Automatic failover
- **Kafka Replication:** Multi-broker setup prevents message loss
- **Database Backups:** Daily backups enable recovery
- **Consumer Idempotency:** Prevents duplicate processing
- **Health Checks:** Automatic server removal from pool
- **Monitoring:** Early detection of issues

All components are designed to gracefully degrade rather than fail completely.
