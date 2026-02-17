---

# Infrastructure Engineering Assignment

## Transaction Processing System

---

## 1. System Overview

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


