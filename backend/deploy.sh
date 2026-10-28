#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "   Sensor Backend - Docker Deployment Script   "
echo "================================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env file with your configuration before continuing!${NC}"
    echo ""
    echo "Required changes:"
    echo "  1. DB_PASSWORD - Set a secure database password"
    echo "  2. JWT_SECRET - Generate using: node -e \"console.log(require('crypto').randomBytes(64).toString('hex'))\""
    echo "  3. EMAIL_* - Configure if using email features"
    echo ""
    read -p "Press Enter after you've configured .env file..."
fi

echo -e "${GREEN}✅ .env file found${NC}"
echo ""

# Source .env file
export $(cat .env | grep -v '^#' | xargs)

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Build images
echo ""
echo "🔨 Building Docker images..."
docker-compose build

# Start services
echo ""
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check service status
echo ""
echo "📊 Service Status:"
docker-compose ps

# Test backend health
echo ""
echo "🔍 Testing backend health..."
sleep 5

HEALTH_CHECK=$(curl -s http://localhost:${SERVER_PORT:-5010}/health)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend is healthy!${NC}"
    echo "$HEALTH_CHECK" | jq '.' 2>/dev/null || echo "$HEALTH_CHECK"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    echo "Checking logs..."
    docker-compose logs --tail=50 backend
fi

echo ""
echo "================================================"
echo "   Deployment Complete!                        "
echo "================================================"
echo ""
echo "API is running at: http://localhost:${SERVER_PORT:-5010}"
echo "Database is running at: localhost:${DB_PORT:-5432}"
echo ""
echo "Useful commands:"
echo "  - View logs:        docker-compose logs -f"
echo "  - Stop services:    docker-compose down"
echo "  - Restart:          docker-compose restart"
echo ""
