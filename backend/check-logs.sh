#!/bin/bash
# Script untuk cek log Docker container backend
# Jalankan di server dengan: bash check-logs.sh

echo "=== Checking backend container logs ==="
docker logs sensor_backend --tail 50

echo ""
echo "=== Checking for MQTT messages ==="
docker logs sensor_backend --tail 100 | grep -i "mqtt\|soil\|gps\|sensor"
