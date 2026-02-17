# Redis Server – srv-redis-01
Private IP: 10.0.0.40
Role: Session storage

---

## Installation

sudo apt install redis-server -y
sudo systemctl enable redis-server

---

## Configuration

File: /etc/redis/redis.conf

bind 10.0.0.40
protected-mode yes
appendonly yes
maxmemory 512mb
maxmemory-policy allkeys-lru

AOF ensures durability.

---

## Security

Port 6379 restricted to 10.0.0.0/24 only.

Not exposed publicly.

---

## Verification

redis-cli ping
Expected: PONG
