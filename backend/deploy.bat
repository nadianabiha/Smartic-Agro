@echo off
REM Sensor Backend - Docker Deployment Script for Windows

echo ================================================
echo    Sensor Backend - Docker Deployment Script
echo ================================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not installed. Please install Docker Desktop first.
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose is not installed. Please install Docker Desktop first.
    exit /b 1
)

echo [OK] Docker and Docker Compose are installed
echo.

REM Check if .env file exists
if not exist .env (
    echo [WARNING] .env file not found. Creating from .env.example...
    copy .env.example .env
    echo.
    echo [WARNING] Please edit .env file with your configuration before continuing!
    echo.
    echo Required changes:
    echo   1. DB_PASSWORD - Set a secure database password
    echo   2. JWT_SECRET - Generate using: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
    echo   3. EMAIL_* - Configure if using email features
    echo.
    pause
)

echo [OK] .env file found
echo.

REM Stop existing containers
echo [STEP] Stopping existing containers...
docker-compose down

REM Build images
echo.
echo [STEP] Building Docker images...
docker-compose build

REM Start services
echo.
echo [STEP] Starting services...
docker-compose up -d

REM Wait for services
echo.
echo [STEP] Waiting for services to start...
timeout /t 10 /nobreak >nul

REM Check service status
echo.
echo [INFO] Service Status:
docker-compose ps

REM Test backend health
echo.
echo [STEP] Testing backend health...
timeout /t 5 /nobreak >nul

curl -s http://localhost:5010/health
if errorlevel 1 (
    echo [ERROR] Backend health check failed
    echo Checking logs...
    docker-compose logs --tail=50 backend
) else (
    echo [OK] Backend is healthy!
)

echo.
echo ================================================
echo    Deployment Complete!
echo ================================================
echo.
echo API is running at: http://localhost:5010
echo Database is running at: localhost:5432
echo.
echo Useful commands:
echo   - View logs:        docker-compose logs -f
echo   - Stop services:    docker-compose down
echo   - Restart:          docker-compose restart
echo.
pause
