# LiteSpeed Web Server – Producer Role
Hostname: srv-web-01 / srv-web-02
Private IP: 10.0.0.20 / 10.0.0.21
Role: Handles HTTP requests, stores sessions in Redis, produces events to Kafka

---

## A. Base Configuration

Ubuntu 22.04 LTS

sudo apt update && sudo apt upgrade -y
sudo adduser deploy
sudo usermod -aG sudo deploy

Firewall:
sudo ufw allow 80/tcp
sudo ufw allow from 10.0.0.10   # Allow only Load Balancer
sudo ufw enable

Web servers are NOT publicly accessible.
Only Load Balancer can reach them.

---

## B. OpenLiteSpeed Installation

wget https://openlitespeed.org/packages/openlitespeed-1.7.16.tgz
tar -xzf openlitespeed-1.7.16.tgz
sudo ./install.sh

Enable:
sudo systemctl enable lsws

---

## C. PHP Configuration

Install PHP:
sudo apt install lsphp81 lsphp81-curl lsphp81-mysql -y

Edit php.ini:

session.save_handler = redis
session.save_path = "tcp://10.0.0.40:6379"

This ensures stateless web servers.

---

## D. Kafka Producer Configuration

Install Python client:
pip3 install kafka-python

Example Producer Code:

from kafka import KafkaProducer
producer = KafkaProducer(bootstrap_servers='10.0.0.30:9092')

producer.send('events', b'UserCreated')

---

## E. Security

Open Ports:
- 80 (internal only)
- 22 (restricted)

Closed:
- 9092
- 6379
- 5432

Services bind to private IP only.

---

## F. Performance Tuning

worker_processes auto
KeepAlive On
MaxConnections 10000

---

## G. Verification

systemctl status lsws
curl http://10.0.0.20
