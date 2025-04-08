#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x
apt update -y
apt install -y docker.io docker-compose
systemctl start docker
systemctl enable docker
cd /home/marianamechyk/app
docker-compose up -d
