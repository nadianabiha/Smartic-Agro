# Docker Deployment Guide - SmartICAgro Backend

## Prerequisites

- Docker Engine 20.10+ dan Docker Compose V2+
- Port yang tersedia: 5010 (backend), 5434 (PostgreSQL)

## Quick Start

### 1. Setup Environment Variables

```bash
# Copy file .env.example menjadi .env
cp .env.example .env

# Edit .env dan ubah nilai-nilai berikut:
# - DB_PASSWORD: Password database yang aman
# - JWT_SECRET: Secret key untuk JWT (minimal 32 karakter random)
# - EMAIL_* : Konfigurasi SMTP jika menggunakan fitur email
```

### 2. Build dan Start Services

```bash
# Build dan start semua services (database + backend)
docker-compose up -d

# Atau build terlebih dahulu lalu start
docker-compose build
docker-compose up -d
```

### 3. Verify Deployment

```bash
# Cek status containers
docker-compose ps

# Cek logs backend
docker-compose logs -f backend

# Cek logs database
docker-compose logs -f postgres

# Test health endpoint
curl http://localhost:5010/health
```

## Docker Commands Reference

### Start/Stop Services

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop dan hapus volumes (WARNING: menghapus data database!)
docker-compose down -v
```

### Monitoring

```bash
# Lihat logs semua services
docker-compose logs -f

# Lihat logs backend saja
docker-compose logs -f backend

# Lihat logs database saja
docker-compose logs -f postgres

# Lihat status containers
docker-compose ps

# Lihat resource usage
docker stats
```

### Maintenance

```bash
# Restart backend service
docker-compose restart backend

# Restart database service
docker-compose restart postgres

# Rebuild backend (setelah code changes)
docker-compose up -d --build backend

# Execute command di container
docker-compose exec backend sh
docker-compose exec postgres psql -U postgres -d sensor_db
```

## Database Management

### Akses Database

```bash
# Masuk ke PostgreSQL shell
docker-compose exec postgres psql -U postgres -d sensor_db

# Atau dari local machine (jika psql terinstall)
psql -h localhost -p 5434 -U postgres -d sensor_db
```

### Backup Database

```bash
# Backup database
docker-compose exec postgres pg_dump -U postgres sensor_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
docker-compose exec -T postgres psql -U postgres sensor_db < backup.sql
```

### Migration

```bash
# Run migration script
docker-compose exec backend node database/migrator.js
```

## Production Deployment

### Security Checklist

1. ✅ Ubah `DB_PASSWORD` dengan password yang kuat
2. ✅ Generate JWT_SECRET yang unik dan aman:
   ```bash
   node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
   ```
3. ✅ Set `NODE_ENV=production`
4. ✅ Konfigurasi firewall untuk restrict port 5434 (hanya akses internal)
5. ✅ Setup SSL/TLS dengan reverse proxy (Nginx/Traefik)
6. ✅ Enable backup otomatis untuk database
7. ✅ Monitor logs dan resource usage

### Environment Variables (Production)

```bash
NODE_ENV=production
SERVER_HOST=0.0.0.0
SERVER_PORT=5010

DB_HOST=postgres
DB_PORT=5432
DB_NAME=sensor_db
DB_USER=postgres
DB_PASSWORD=<STRONG_PASSWORD>

MQTT_BROKER=broker.hivemq.com
MQTT_PORT=1883
MQTT_TOPIC=sensor/data

JWT_SECRET=<RANDOM_64_CHAR_HEX>
JWT_EXPIRES_IN=24h

EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=<YOUR_EMAIL>
EMAIL_PASSWORD=<APP_PASSWORD>
EMAIL_FROM=SmartICAgro <your-email@gmail.com>
```

### Reverse Proxy Setup (Nginx)

```nginx
server {
    listen 80;
    server_name api.smarticagro.com;

    location / {
        proxy_pass http://localhost:5010;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Troubleshooting

### Backend tidak bisa connect ke Database

```bash
# Cek database sudah ready
docker-compose logs postgres | grep "ready to accept connections"

# Cek network connectivity
docker-compose exec backend ping postgres

# Restart services dengan urutan
docker-compose down
docker-compose up -d postgres
# Tunggu ~10 detik
docker-compose up -d backend
```

### Port sudah digunakan

```bash
# Cek apa yang menggunakan port
netstat -ano | findstr :5010
netstat -ano | findstr :5434

# Atau ubah port di .env
SERVER_PORT=5011
DB_PORT=5435
```

### Rebuild from Scratch

```bash
# Stop semua containers
docker-compose down -v

# Hapus images
docker rmi backend-backend postgres:15-alpine

# Build ulang
docker-compose up -d --build
```

## Testing API

### Health Check

```bash
curl http://localhost:5010/health
```

### Register User

```bash
curl -X POST http://localhost:5010/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Login

```bash
curl -X POST http://localhost:5010/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Get Latest Sensor Data

```bash
curl http://localhost:5010/api/sensor/latest
```

### Prediction (dengan token)

```bash
curl -X POST http://localhost:5010/api/predict \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "N": 90,
    "P": 42,
    "K": 43,
    "temperature": 20.8,
    "humidity": 82,
    "ph": 6.5,
    "altitude": 500
  }'
```

## Performance Tuning

### Database Optimization

Edit `docker-compose.yml` dan tambahkan di service postgres:

```yaml
command: 
  - "postgres"
  - "-c"
  - "max_connections=100"
  - "-c"
  - "shared_buffers=256MB"
  - "-c"
  - "effective_cache_size=1GB"
```

### Backend Scaling

```bash
# Scale backend ke 3 instances (gunakan load balancer)
docker-compose up -d --scale backend=3
```

## Monitoring & Logging

### Setup Log Rotation

Tambahkan di `docker-compose.yml`:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Prometheus Metrics (Optional)

Install prom-client dan expose metrics endpoint.

## Support

Untuk issues atau pertanyaan, buka issue di GitHub repository atau hubungi tim development.
