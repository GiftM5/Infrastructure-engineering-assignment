#!/bin/bash
set -e

# MySQL Users Setup Script
# Creates application users with appropriate privilege separation

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-}"
DB_NAME="${DB_NAME:-cashit}"

if [ -n "$DB_PASS" ]; then
    MYSQL_CONN="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS"
else
    MYSQL_CONN="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER"
fi

echo "Creating MySQL users..."

$MYSQL_CONN <<EOF
-- Application user (read/write for app operations)
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT SELECT, INSERT, UPDATE ON $DB_NAME.* TO 'app_user'@'%';

-- Analytics user (read-only)
CREATE USER IF NOT EXISTS 'analytics'@'%' IDENTIFIED BY 'analytics_password';
GRANT SELECT ON $DB_NAME.* TO 'analytics'@'%';

-- Backup user (backup operations)
CREATE USER IF NOT EXISTS 'backup_user'@'%' IDENTIFIED BY 'backup_password';
GRANT SELECT, LOCK TABLES ON $DB_NAME.* TO 'backup_user'@'%';

-- Replication user
CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY 'repl_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';

-- DBA user (admin operations)
CREATE USER IF NOT EXISTS 'dba'@'%' IDENTIFIED BY 'dba_password';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO 'dba'@'%';

FLUSH PRIVILEGES;
EOF

echo "✓ MySQL users created"
