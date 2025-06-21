#!/bin/bash

# Build and start on port 8001
#/usr/local/bin/docker-compose up -d --build
podman-compose up -d --build
# Test the application
curl http://localhost:8001/

# Check health
curl http://localhost:8001/health

exit