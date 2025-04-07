#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x
apt update -y
apt install -y docker.io docker-compose
systemctl start docker
systemctl enable docker
# Pull and run Docker images
# docker pull marianamechyk/react-frontend:latest
# docker run -d --name frontend -p 5173:5173 marianamechyk/react-frontend:latest
# docker pull marianamechyk/django-backend:latest
# docker run -d --name backend -p 8000:8000 marianamechyk/django-backend:latest
# docker pull postgres
# docker pull prom/prometheus:latest
# docker pull grafana/grafana:latest
# docker run -d --name prometheus -p 9090:9090 prom/prometheus:latest
# docker run -d --name grafana -p 3000:3000 grafana/grafana:latest
cd /home/ubuntu/app
docker-compose up -d
