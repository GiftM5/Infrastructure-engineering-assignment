# Infrastructure Engineering Assignment - Server Architecture Deployment & Configuration

## Project Overview

This project documents a production-ready server configuration for a distributed infrastructure handling web traffic, asynchronous message processing, and persistent data storage. The infrastructure is designed using Docker containers for easy deployment and testing.

## Quick Start with Docker

### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 8GB+ RAM available
- 20GB+ disk space

### Deploy

```bash
cd /home/mpho/CashIT-Assignment/Infrastructure-engineering-assignment
docker-compose up -d
docker-compose ps
```

### Access Services
- **Load Balancer:** http://localhost
- **Nginx Status:** http://localhost:8080/nginx_status
- **PHPMyAdmin:** http://localhost:8888

## Documentation

### Server Documentation
- [Load Balancer (Nginx)](docs/load-balancer.md)
- [LiteSpeed Producer Web Servers](docs/litespeed-producer.md)
- [LiteSpeed Consumer Web Servers](docs/litespeed-consumer.md)
- [Kafka Broker](docs/kafka-broker.md)
- [Redis Server](docs/redis.md)
- [Database Writer Consumers](docs/db-writer.md)
- [MySQL Database Server](docs/database.md)

### Operational Guides
- [Failure Scenarios & Recovery](docs/failure-scenarios.md)
- [Scaling Strategy](docs/scaling-strategy.md)

## Architecture

```
┌────────────────────────────────┐
│   Load Balancer (Nginx)        │
│   (Port 80/443, SSL/TLS)       │
└───────────┬────────────────────┘
            │
   ┌────────┼────────┬─────────┐
   ▼        ▼        ▼         ▼
┌────┐  ┌────┐  ┌────┐   ┌─────────┐
│LS1 │  │LS2 │  │LS3 │   │  Redis  │
│P   │  │P   │  │C   │   │Session  │
│C   │  │    │  │    │   └─────────┘
└────┘  └────┘  └────┘
  │       │       │
  └───────┼───────┘
          ▼
      ┌─────────┐
      │  Kafka  │
      │ Broker  │
      └─────────┘
          │
      ┌───┴───┐
      ▼       ▼
   ┌────┐  ┌────┐
   │DB1 │  │DB2 │  (Consumers)
   └────┘  └────┘
      │       │
      └───┬───┘
          ▼
       ┌─────────┐
       │ MySQL   │
       │Database │
       └─────────┘
```

**Legend:** P = Producer, C = Consumer

## Project Structure

```
├── configs/                    # Service configurations
│   ├── kafka/server.properties
│   ├── mysql/my.cnf
│   ├── ngnix/nginx.conf
│   ├── php/php.ini
│   └── redis/redis.conf
├── docs/                       # Documentation
│   ├── load-balancer.md
│   ├── litespeed-producer.md
│   ├── litespeed-consumer.md
│   ├── kafka-broker.md
│   ├── redis.md
│   ├── db-writer.md
│   ├── database.md
│   ├── failure-scenarios.md
│   ├── scaling-strategy.md
│   └── README.md
├── scripts/                    # Installation scripts
│   ├── base-setup.sh
│   ├── install-kafka.sh
│   ├── install-redis.sh
│   └── install-web.sh
└── docker-compose.yml          # Docker orchestration
```

## Key Features

### High Availability
- Load balancer with health checks
- Automatic server removal on failure
- Kafka replication for message durability
- Database backups and recovery

### Scalability
- Horizontal web server scaling
- Kafka partition scaling
- Database connection pooling
- Redis distributed caching

### Security
- SSL/TLS termination
- SSH hardening
- Firewall rules
- Fail2ban protection
- Database user permissions

### Reliability
- Idempotency checks
- Dead-letter queues
- Automatic retry logic
- Point-in-time recovery

## Operational Procedures

### Health Check
```bash
docker-compose ps
docker-compose logs -f
docker stats
```

### Backup Database
```bash
docker-compose exec database mysqldump -u backup_user -ppassword cashit > /backups/cashit-$(date +%Y%m%d).sql
```

### Monitor Kafka
```bash
docker-compose exec kafka kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group db_writers --describe
```

### Check Redis Memory
```bash
docker-compose exec redis redis-cli INFO memory
```

## Failure Scenarios

### Load Balancer Failure
- Automatic failover via secondary LB
- Traffic reroutes to healthy servers

### Kafka Failure
- Consumer lag accumulates
- Resumes after restart
- No data loss

### Redis Failure
- Sessions lost (users logged out)
- Automatic recovery
- RTO: 2-5 minutes

### Database Failure
- Restore from backup
- Point-in-time recovery
- RTO: 10-30 minutes

For detailed failure handling, see [failure-scenarios.md](failure-scenarios.md)

## Scaling Examples

### Add Web Server
```bash
docker run -d litespeedtech/openlitespeed:latest
# Update nginx.conf upstream
docker-compose restart nginx
```

### Scale Kafka Partitions
```bash
docker-compose exec kafka kafka-topics.sh --alter --topic user.signup --partitions 6 --bootstrap-server kafka:9092
```

### Add Consumer
```bash
docker run -d -e "CONSUMER_GROUP=db_writers" consumer:latest
```

## Security

### Implemented
✅ SSL/TLS termination
✅ SSH hardening
✅ Firewall rules
✅ Fail2ban protection
✅ Least privilege database users
✅ Security headers
✅ Rate limiting
✅ Disabled dangerous functions

### Recommendations for Production
- Web Application Firewall (WAF)
- Secrets manager (Vault, AWS Secrets)
- Database encryption at rest
- API authentication (OAuth 2.0)
- Regular security audits
- DDoS protection (CloudFlare, AWS Shield)

## Monitoring Recommendations

### Key Metrics
- Load Balancer: connections, latency, errors
- Web Servers: CPU, memory, requests
- Kafka: lag, throughput, rebalancing
- Redis: memory, eviction, connections
- Database: query latency, replication lag

### Tools
- **Monitoring:** Prometheus, Grafana
- **Logging:** ELK Stack
- **Tracing:** Jaeger, Zipkin
- **Alerts:** AlertManager, PagerDuty

## Testing

### Load Testing
```bash
ab -n 10000 -c 100 http://localhost/
```

### Failover Testing
```bash
docker-compose stop litespeed1
curl http://localhost/  # Should still work
```

## References

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Redis Documentation](https://redis.io/documentation)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Docker Documentation](https://docs.docker.com/)

## Next Steps

1. Review all configuration files
2. Update passwords and credentials
3. Configure DNS and SSL certificates
4. Set up backup storage
5. Configure monitoring and alerting
6. Perform load and failover testing
7. Conduct security audit
8. Document any customizations

---

**Last Updated:** February 17, 2024

For more information, see individual component documentation.

This project is a simulation of a real production server setup.

The system is designed to:

* Receive traffic from users
* Distribute traffic to web servers
* Store user sessions
* Send events for processing
* Save final results in a database
* Handle failures
* Scale when traffic increases

This setup follows real-world production practices.

---

## 2. What This System Does

This system acts like a payment or transaction platform.

Example:

1. A user sends a payment request.
2. The request goes to the Load Balancer.
3. The Load Balancer sends it to one of the LiteSpeed web servers.
4. The web server:

   * Checks the request
   * Stores session data in Redis
   * Sends an event to Apache Kafka
5. Kafka consumers read the event.
6. The DB Writer saves the result in the database.
7. The system stores the final transaction status.

This design helps the system handle many users and prevents overload.

---

## 3. How The System Is Connected

```
Client
   ↓
Load Balancer
   ↓
LiteSpeed Web Servers
   ↓
Redis (sessions)
   ↓
Kafka
   ↓
Consumers
   ↓
DB Writers
   ↓
Database
```

---

## 4. Servers in This System

* Load Balancer – receives public traffic
* LiteSpeed Servers – handle web requests
* Redis – stores session data
* Kafka – handles event communication
* Consumers – process events
* DB Writers – write to the database
* Database – stores final data


