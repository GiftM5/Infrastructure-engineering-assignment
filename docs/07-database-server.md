# PostgreSQL Database – srv-db-01
Private IP: 10.0.0.60

Role: Final persistence layer

---

## Installation

sudo apt install postgresql postgresql-contrib -y
sudo systemctl enable postgresql

---

## Configuration

Edit postgresql.conf:
listen_addresses = '10.0.0.60'

Edit pg_hba.conf:
host all all 10.0.0.0/24 md5

---

## Create Database

sudo -u postgres psql

CREATE DATABASE appdb;
CREATE USER appuser WITH PASSWORD 'securepassword';
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;

---

## Table Structure

CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    data TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

---

## Security

Port 5432 restricted to 10.0.0.50 only.

Not publicly accessible.

---

## Verification

systemctl status postgresql
psql -U appuser -d appdb
