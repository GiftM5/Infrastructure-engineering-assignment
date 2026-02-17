# Failure Analysis

---

## 1. Load Balancer Failure

Impact:
System becomes unreachable.

Mitigation:
Deploy secondary load balancer.
Use Keepalived with Virtual IP.

---

## 2. Kafka Broker Crash

Impact:
Producers retry.
Consumers pause.

Mitigation:
Enable replication across brokers.
Use a 3-node Kafka cluster in production.

---

## 3. Redis Crash

Impact:
Session loss if persistence disabled.

Mitigation:
Enable AOF persistence.
Deploy Redis replica.

---

## 4. DB Writer Failure

Impact:
Messages remain in Kafka.
No data loss.

Mitigation:
Consumer group rebalance automatically.
Offset committed only after successful DB write.

---

## 5. Duplicate Write Prevention

Use:
- Idempotent database keys
- Unique constraints
- Upsert strategy

---

## 6. Data Loss Prevention

- Kafka retention 7 days
- Offset management
- Retry logic
- Dead-letter queue
