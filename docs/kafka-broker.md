
---

# Kafka Quick Setup & Verification

## 1. Install & Start

```bash
# Install Kafka & Zookeeper
bash scripts/install-kafka.sh

# Start services
systemctl start zookeeper
systemctl start kafka

# Verify topics
kafka-topics.sh --list --bootstrap-server kafka:9092
```

---

## 2. System Setup & Security

```bash
# Create Kafka user & directories
useradd -m -s /bin/bash kafka
mkdir -p /var/kafka/{logs,data}
chown -R kafka:kafka /var/kafka
chmod 750 /var/kafka

# Firewall (adjust network for production)
ufw allow 22/tcp      # SSH
ufw allow 9092/tcp    # Kafka
ufw allow 2181/tcp    # Zookeeper
ufw enable

# Fail2ban basic
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

---

## 3. Kafka Configuration Essentials (`server.properties`)

```ini
# Broker
broker.id=1
num.partitions=3
log.dirs=/var/kafka/logs

# Network
listeners=PLAINTEXT://kafka:9092
advertised.listeners=PLAINTEXT://kafka:9092

# Logs & retention
log.retention.hours=168
log.segment.bytes=1GB
log.cleanup.policy=delete

# Performance
num.network.threads=8
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
connections.max.idle.ms=540000
compression.type=snappy

# Zookeeper (if used)
zookeeper.connect=zookeeper:2181
```

---

## 4. Verification / Health Check

```bash
# Zookeeper
nc -z localhost 2181 && echo "Zookeeper ✓"

# Kafka broker
nc -z localhost 9092 && echo "Kafka ✓"

# Broker API check
kafka-broker-api-versions.sh --bootstrap-server localhost:9092

# List topics
kafka-topics.sh --list --bootstrap-server localhost:9092
```

---

## 5. Topic Management

```bash
# Create topic
kafka-topics.sh --create \
  --bootstrap-server kafka:9092 \
  --topic user.signup \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=604800000

# Describe topic
kafka-topics.sh --describe --bootstrap-server kafka:9092 --topic user.signup

# Delete topic
kafka-topics.sh --delete --bootstrap-server kafka:9092 --topic user.signup
```

---

## 6. Consumer Group Monitoring

```bash
# List groups
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --list

# Describe group
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers --describe

# Reset offset
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers \
  --reset-offsets --to-earliest --topic user.signup --execute
```

---

## 7. Message Inspection

```bash
# Consume messages
kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic user.signup --from-beginning --max-messages 10
```

---

## 8. Monitoring & Performance

```bash
# Process & memory
watch -n 1 'ps aux | grep kafka'

# Disk usage
watch -n 5 'df -h /var/kafka && du -sh /var/kafka/logs'

# Network
ss -tan | grep 9092

# Optional JMX monitoring
jconsole &
```

---

## 9. Failure Recovery

```bash
# Restart broker
systemctl restart kafka

# Check logs
journalctl -u kafka -f

# Reset consumer offsets if lagging
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers \
  --reset-offsets --to-latest --topic user.signup --execute
```

---