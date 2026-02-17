#!/bin/bash

apt install redis-server -y
systemctl enable redis-server
