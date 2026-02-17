#!/bin/bash

apt install haproxy -y
systemctl enable haproxy
systemctl start haproxy
