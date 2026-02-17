#!/bin/bash

apt install default-jdk -y

wget https://downloads.apache.org/kafka/3.6.0/kafka_2.13-3.6.0.tgz
tar -xzf kafka_2.13-3.6.0.tgz
mv kafka_2.13-3.6.0 /opt/kafka

useradd kafka
chown -R kafka:kafka /opt/kafka
