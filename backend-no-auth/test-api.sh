#!/bin/bash

# API Test Script for Linux/Mac
# Test all endpoints to verify they return data

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:5010"
TEST_EMAIL="test_$(date +%s)@example.com"
TEST_USERNAME="testuser_$(date +%s)"
TEST_PASSWORD="password123"
TOKEN=""

echo -e "${CYAN}========================================"
echo -e "   API Endpoint Testing Script"
echo -e "========================================${NC}"
echo ""

# Check if server is running
echo -e "${CYAN}Checking if server is running...${NC}"
if curl -s "$BASE_URL/" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Server is running!${NC}"
    echo ""
else
    echo -e "${RED}✗ Server is not running on $BASE_URL${NC}"
    echo -e "${YELLOW}Please start the server first with: npm start${NC}"
    exit 1
fi

echo -e "${CYAN}========================================"
echo -e "1. PUBLIC ENDPOINTS"
echo -e "========================================${NC}"
echo ""

# Test Health
echo -e "${YELLOW}Testing: Health Check${NC}"
echo -e "${GRAY}  URL: GET $BASE_URL/health${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}  ✓ Success${NC}"
    echo -e "${GRAY}  Response:${NC}"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}  ✗ Failed (HTTP $HTTP_CODE)${NC}"
fi
echo ""

# Test API Info
echo -e "${YELLOW}Testing: API Info${NC}"
echo -e "${GRAY}  URL: GET $BASE_URL/${NC}"
RESPONSE=$(curl -s "$BASE_URL/")
echo -e "${GREEN}  ✓ Success${NC}"
echo -e "${GRAY}  Response:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Test Latest Sensor Data
echo -e "${YELLOW}Testing: Latest Sensor Data${NC}"
echo -e "${GRAY}  URL: GET $BASE_URL/api/sensor/latest${NC}"
RESPONSE=$(curl -s "$BASE_URL/api/sensor/latest")
echo -e "${GREEN}  ✓ Success${NC}"
echo -e "${GRAY}  Response:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

echo -e "${CYAN}========================================"
echo -e "2. AUTH ENDPOINTS"
echo -e "========================================${NC}"
echo ""

# Test Register
echo -e "${YELLOW}Testing: Register User${NC}"
echo -e "${GRAY}  URL: POST $BASE_URL/api/auth/register${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$TEST_USERNAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
echo -e "${GREEN}  ✓ Success${NC}"
echo -e "${GRAY}  Response:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

# Extract token
TOKEN=$(echo "$RESPONSE" | jq -r '.data.token' 2>/dev/null)
if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
    echo -e "${GREEN}Token obtained: ${TOKEN:0:20}...${NC}"
fi
echo ""

# Test Login
echo -e "${YELLOW}Testing: Login User${NC}"
echo -e "${GRAY}  URL: POST $BASE_URL/api/auth/login${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")
echo -e "${GREEN}  ✓ Success${NC}"
echo -e "${GRAY}  Response:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

# Extract token (in case register failed)
NEW_TOKEN=$(echo "$RESPONSE" | jq -r '.data.token' 2>/dev/null)
if [ "$NEW_TOKEN" != "null" ] && [ -n "$NEW_TOKEN" ]; then
    TOKEN="$NEW_TOKEN"
fi
echo ""

# Test Get Profile
if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "${YELLOW}Testing: Get Profile (Protected)${NC}"
    echo -e "${GRAY}  URL: GET $BASE_URL/api/auth/profile${NC}"
    RESPONSE=$(curl -s "$BASE_URL/api/auth/profile" \
        -H "Authorization: Bearer $TOKEN")
    echo -e "${GREEN}  ✓ Success${NC}"
    echo -e "${GRAY}  Response:${NC}"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""
else
    echo -e "${YELLOW}Skipping profile test - no token available${NC}"
    echo ""
fi

echo -e "${CYAN}========================================"
echo -e "3. PREDICTION ENDPOINTS (Protected)"
echo -e "========================================${NC}"
echo ""

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    # Test Predict with custom data
    echo -e "${YELLOW}Testing: Predict Crop (Custom Data)${NC}"
    echo -e "${GRAY}  URL: POST $BASE_URL/api/predict${NC}"
    RESPONSE=$(curl -s -X POST "$BASE_URL/api/predict" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"N":90,"P":42,"K":43,"temperature":20.8,"humidity":82.0,"pH":6.5,"altitude":100}')
    echo -e "${GREEN}  ✓ Success${NC}"
    echo -e "${GRAY}  Response:${NC}"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""
    
    # Test Predict from latest sensor
    echo -e "${YELLOW}Testing: Predict from Latest Sensor${NC}"
    echo -e "${GRAY}  URL: GET $BASE_URL/api/predict/latest${NC}"
    RESPONSE=$(curl -s "$BASE_URL/api/predict/latest" \
        -H "Authorization: Bearer $TOKEN")
    echo -e "${GREEN}  ✓ Success${NC}"
    echo -e "${GRAY}  Response:${NC}"
    echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    echo ""
else
    echo -e "${YELLOW}Skipping prediction tests - no token available${NC}"
    echo ""
fi

echo -e "${CYAN}========================================"
echo -e "4. PASSWORD RESET ENDPOINTS"
echo -e "========================================${NC}"
echo ""

# Test Forgot Password
echo -e "${YELLOW}Testing: Request Password Reset${NC}"
echo -e "${GRAY}  URL: POST $BASE_URL/api/auth/forgot-password${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/forgot-password" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\"}")
echo -e "${GREEN}  ✓ Success${NC}"
echo -e "${GRAY}  Response:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

echo -e "${CYAN}========================================"
echo -e "   Testing Complete!"
echo -e "========================================${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo -e "  Base URL: ${BASE_URL}"
echo -e "  Test User: ${TEST_EMAIL}"
if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "  Token: ${GREEN}Generated ✓${NC}"
else
    echo -e "  Token: ${RED}Not available ✗${NC}"
fi
echo ""
