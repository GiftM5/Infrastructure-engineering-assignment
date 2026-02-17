variable "servers" {
  type = list(string)
  default = [
    "srv-lb-01",
    "srv-web-01",
    "srv-web-02",
    "srv-web-03",
    "srv-kafka-01",
    "srv-redis-01",
    "srv-dbwriter-01",
    "srv-db-01"
  ]
}
