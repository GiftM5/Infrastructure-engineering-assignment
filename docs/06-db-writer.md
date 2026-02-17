# DB Writer – srv-dbwriter-01
Private IP: 10.0.0.50

Role: Consumes Kafka messages and writes to PostgreSQL.

---

## Installation

sudo apt install python3 python3-pip -y
pip3 install kafka-python psycopg2-binary

---

## DB Writer Code Example

import psycopg2
from kafka import KafkaConsumer

conn = psycopg2.connect(
    host="10.0.0.60",
    database="appdb",
    user="appuser",
    password="securepassword"
)

consumer = KafkaConsumer(
    'events',
    bootstrap_servers='10.0.0.30:9092',
    group_id='db-writers',
    enable_auto_commit=False
)

for message in consumer:
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO events(data) VALUES(%s) ON CONFLICT DO NOTHING",
            (message.value.decode(),)
        )
        conn.commit()
    consumer.commit()

---

## Idempotency Strategy

- Use UNIQUE constraint in database
- Use ON CONFLICT DO NOTHING
- Commit offset after DB success

---

## Verification

Check DB:
SELECT * FROM events;
