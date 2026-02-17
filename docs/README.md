# Infrastructure Engineering Assignment - Server Architecture Deployment & Configuration

## Project Overview

This project documents a production-ready server configuration for a distributed infrastructure handling web traffic, asynchronous message processing, and persistent data storage. The infrastructure is designed using Docker containers for easy deployment and testing.


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
