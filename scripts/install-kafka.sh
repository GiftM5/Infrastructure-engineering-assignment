#!/bin/bash

# Install Java (required for Kafka)
sudo apt install default-jdk -y

# Download Kafka
wget https://downloads.apache.org/kafka/2.8.0/kafka_2.12-2.8.0.tgz
tar -xzf kafka_2.12-2.8.0.tgz
sudo mv kafka_2.12-2.8.0 /usr/local/kafka

# Start Zookeeper
/usr/local/kafka/bin/zookeeper-server-start.sh -daemon /usr/local/kafka/config/zookeeper.properties

# Start Kafka
/usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties

# Create a topic
/usr/local/kafka/bin/kafka-topics.sh --create --topic my-topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
