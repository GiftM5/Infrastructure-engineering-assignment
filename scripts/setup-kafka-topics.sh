#!/bin/bash
set -e

# Kafka Topics Setup Script
# Creates topics for event streaming

KAFKA_BROKER="${KAFKA_BROKER:-kafka:9092}"
KAFKA_HOME="${KAFKA_HOME:-/opt/kafka}"

echo "Checking Kafka broker availability..."
until nc -z ${KAFKA_BROKER%:*} ${KAFKA_BROKER#*:}; do
    echo "Waiting for Kafka broker..."
    sleep 2
done

echo "Creating Kafka topics..."

# Create topics with 3 partitions and snappy compression
$KAFKA_HOME/bin/kafka-topics.sh \
    --bootstrap-server "$KAFKA_BROKER" \
    --create \
    --if-not-exists \
    --topic user.signup \
    --partitions 3 \
    --replication-factor 1 \
    --config compression.type=snappy \
    --config retention.ms=604800000

$KAFKA_HOME/bin/kafka-topics.sh \
    --bootstrap-server "$KAFKA_BROKER" \
    --create \
    --if-not-exists \
    --topic user.purchase \
    --partitions 3 \
    --replication-factor 1 \
    --config compression.type=snappy \
    --config retention.ms=604800000

echo "✓ Topics created successfully"
