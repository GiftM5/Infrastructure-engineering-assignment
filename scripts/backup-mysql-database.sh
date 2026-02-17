#!/bin/bash
set -e

# MySQL Backup Script
# Creates timestamped backups with automatic 7-day retention

BACKUP_DIR="${BACKUP_DIR:-/backups/mysql}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-backup_user}"
DB_PASS="${DB_PASS:-backup_password}"
DB_NAME="${DB_NAME:-cashit}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "Starting backup of $DB_NAME..."

mysqldump \
    -h "$DB_HOST" \
    -P "$DB_PORT" \
    -u "$DB_USER" \
    -p"$DB_PASS" \
    --single-transaction \
    --lock-tables=false \
    "$DB_NAME" | gzip > "$BACKUP_FILE"

echo "✓ Backup created: $BACKUP_FILE"

# Cleanup old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +$RETENTION_DAYS -delete
echo "✓ Cleanup complete"
