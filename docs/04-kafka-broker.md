# Kafka Broker – srv-kafka-01
Private IP: 10.0.0.30
Role: Central asynchronous message broker

---

## A. Installation

sudo apt install default-jdk -y
wget https://downloads.apache.org/kafka/3.6.0/kafka_2.13-3.6.0.tgz
tar -xzf kafka_2.13-3.6.0.tgz
mv kafka_2.13-3.6.0 /opt/kafka

---

## B. Configuration

File: /opt/kafka/config/server.properties

broker.id=1
listeners=PLAINTEXT://10.0.0.30:9092
advertised.listeners=PLAINTEXT://10.0.0.30:9092
num.partitions=3
default.replication.factor=1
log.retention.hours=168

Justification:
- 3 partitions allows parallelism
- 7-day retention supports replay capability

---

## C. Security

Port 9092 restricted to internal network only.
Kafka not exposed publicly.

---

## D. Consumer Groups

Consumers belong to same group.
Offsets committed after successful DB write.
Ensures at-least-once delivery.

---

## E. Dead Letter Queue

Failed messages sent to topic:
dead-letter-topic

Prevents data loss.

---

## F. Verification

Create topic:
bin/kafka-topics.sh --create --topic test --bootstrap-server 10.0.0.30:9092

Produce:
bin/kafka-console-producer.sh --topic test --bootstrap-server 10.0.0.30:9092

Consume:
bin/kafka-console-consumer.sh --topic test --from-beginning --bootstrap-server 10.0.0.30:9092
