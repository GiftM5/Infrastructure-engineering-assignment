#!/bin/bash
set -e

# Redis Backup Script
# Creates timestamped backups with automatic 7-day retention

BACKUP_DIR="${BACKUP_DIR:-/backups/redis}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/dump_${TIMESTAMP}.rdb.gz"

echo "Starting Redis backup..."

# Trigger background save
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" BGSAVE

# Wait for save to complete
while true; do
    RESULT=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" LASTSAVE)
    if [ "$?" -eq 0 ]; then
        break
    fi
    sleep 1
done

# Copy and compress
if [ -f /var/lib/redis/dump.rdb ]; then
    gzip -c /var/lib/redis/dump.rdb > "$BACKUP_FILE"
    echo "✓ Backup created: $BACKUP_FILE"
else
    echo "✗ Redis dump file not found"
    exit 1
fi

# Cleanup old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "dump_*.rdb.gz" -mtime +$RETENTION_DAYS -delete
echo "✓ Cleanup complete"
