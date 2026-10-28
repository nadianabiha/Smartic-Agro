# Quick Start - Docker Deployment

## 🚀 Deploy dalam 3 Langkah

### 1. Setup Environment
```bash
# Copy .env.example ke .env
cp .env.example .env

# Edit .env (minimal ubah ini):
# - DB_PASSWORD=your_secure_password
# - JWT_SECRET=your_random_secret_key
```

**Generate JWT Secret:**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 2. Deploy dengan Docker
```bash
# Windows
deploy.bat

# Linux/Mac
chmod +x deploy.sh
./deploy.sh
```

### 3. Verify
```bash
# Check health
curl http://localhost:5010/health

# Test API
curl http://localhost:5010/
```

## 📦 What's Included

- ✅ Backend API (Node.js + Express)
- ✅ PostgreSQL Database
- ✅ WebSocket for real-time updates
- ✅ ML Prediction Service (Python)
- ✅ MQTT Client
- ✅ JWT Authentication
- ✅ Email Service

## 🔌 Endpoints

```
Backend:  http://localhost:5010
Database: localhost:5434 (PostgreSQL)
```

### API Endpoints:
- `GET /health` - Health check
- `GET /api/sensor/latest` - Latest sensor data
- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login
- `POST /api/predict` - Crop prediction (auth required)

## 🛠️ Management Commands

```bash
# View logs
docker-compose logs -f backend
docker-compose logs -f postgres

# Stop services
docker-compose down

# Restart services
docker-compose restart

# Rebuild after code changes
docker-compose up -d --build backend
```

## 🗄️ Database Management

### Access Database:
```bash
docker-compose exec postgres psql -U postgres -d sensor_db
```

### Backup Database:
```bash
docker-compose exec postgres pg_dump -U postgres sensor_db > backup.sql
```

### Restore Database:
```bash
docker-compose exec -T postgres psql -U postgres sensor_db < backup.sql
```

## 🔒 Production Checklist

- [ ] Change `DB_PASSWORD` to strong password
- [ ] Generate secure `JWT_SECRET` (64 char hex)
- [ ] Set `NODE_ENV=production`
- [ ] Configure email SMTP settings
- [ ] Setup SSL/TLS (use Nginx/Traefik reverse proxy)
- [ ] Enable firewall for port 5433
- [ ] Setup automated database backups
- [ ] Configure monitoring and alerts

## 🐛 Troubleshooting

### Backend tidak bisa connect ke database?
```bash
# Wait for database to be ready
docker-compose logs postgres | grep "ready"

# Restart with proper order
docker-compose down
docker-compose up -d postgres
sleep 10
docker-compose up -d backend
```

### Port sudah digunakan?
```bash
# Check what's using the port
netstat -ano | findstr :5010

# Change port in .env
SERVER_PORT=5011
DB_PORT=5434
```

### Reset Everything:
```bash
# WARNING: This deletes all data!
docker-compose down -v
docker-compose up -d --build
```

## 📚 More Info

- Full deployment guide: [DEPLOYMENT.md](DEPLOYMENT.md)
- API documentation: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- Docker utilities: Run `docker-utils.bat` for interactive menu

## 🆘 Support

For issues: Open GitHub issue or contact development team
