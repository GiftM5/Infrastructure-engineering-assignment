# LiteSpeed Web Server – Consumer Role
Hostname: srv-web-03
Private IP: 10.0.0.22

Role: Consumes Kafka messages and processes business logic.

---

## Kafka Consumer Configuration

pip3 install kafka-python

Consumer Example:

from kafka import KafkaConsumer

consumer = KafkaConsumer(
    'events',
    bootstrap_servers='10.0.0.30:9092',
    group_id='web-consumers',
    enable_auto_commit=False
)

for message in consumer:
    process(message.value)
    consumer.commit()

Offset commit AFTER processing.
Ensures at-least-once delivery.

---

## Retry Logic

If failure:
- Retry 3 times
- Send to dead-letter-topic

---

## Verification

Consume test messages:
kafka-console-consumer.sh --topic events --from-beginning
