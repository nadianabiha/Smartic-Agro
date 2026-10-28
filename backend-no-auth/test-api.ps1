# API Test Script
# Test all endpoints to verify they return data

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   API Endpoint Testing Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:5010"
$testEmail = "test@example.com"
$testUsername = "testuser"
$testPassword = "password123"
$token = ""

function Test-Endpoint {
    param(
        [string]$name,
        [string]$url,
        [string]$method = "GET",
        [object]$body = $null,
        [hashtable]$headers = @{}
    )
    
    Write-Host "Testing: $name" -ForegroundColor Yellow
    Write-Host "  URL: $method $url" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $url
            Method = $method
            Headers = $headers
            ContentType = "application/json"
        }
        
        if ($body) {
            $params.Body = ($body | ConvertTo-Json)
        }
        
        $response = Invoke-RestMethod @params
        Write-Host "  [OK] Success" -ForegroundColor Green
        Write-Host "  Response:" -ForegroundColor Gray
        $response | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
        Write-Host ""
        return $response
    }
    catch {
        Write-Host "  [FAIL] Failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        Write-Host ""
        return $null
    }
}

# Check if server is running
Write-Host "Checking if server is running..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/" -UseBasicParsing
    Write-Host "[OK] Server is running!" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "[FAIL] Server is not running on $baseUrl" -ForegroundColor Red
    Write-Host "Please start the server first with: npm start" -ForegroundColor Yellow
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. PUBLIC ENDPOINTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test Health
Test-Endpoint -name "Health Check" -url "$baseUrl/health"

# Test API Info
Test-Endpoint -name "API Info" -url "$baseUrl/"

# Test Latest Sensor Data
Test-Endpoint -name "Latest Sensor Data" -url "$baseUrl/api/sensor/latest"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "2. AUTH ENDPOINTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Skip Register - user already exists, just login
Write-Host "Skipping Register - using existing user from akun.txt" -ForegroundColor Yellow
Write-Host ""

# Test Login
$loginBody = @{
    email = $testEmail
    password = $testPassword
}
$loginResponse = Test-Endpoint -name "Login User" -url "$baseUrl/api/auth/login" -method "POST" -body $loginBody

if ($loginResponse -and $loginResponse.data.token) {
    $token = $loginResponse.data.token
}

# Test Get Profile (Protected)
if ($token) {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    Test-Endpoint -name "Get Profile (Protected)" -url "$baseUrl/api/auth/profile" -headers $headers
} else {
    Write-Host "Skipping profile test - no token available" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "3. PREDICTION ENDPOINTS (Protected)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($token) {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    # Test Predict with custom data
    $predictBody = @{
        N = 90
        P = 42
        K = 43
        temperature = 20.8
        humidity = 82.0
        pH = 6.5
        altitude = 100
    }
    Test-Endpoint -name "Predict Crop (Custom Data)" -url "$baseUrl/api/predict" -method "POST" -body $predictBody -headers $headers
    
    # Test Predict from latest sensor
    Test-Endpoint -name "Predict from Latest Sensor" -url "$baseUrl/api/predict/latest" -headers $headers
    
} else {
    Write-Host "Skipping prediction tests - no token available" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "4. PASSWORD RESET ENDPOINTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test Forgot Password Request
$forgotBody = @{
    email = $testEmail
}
Test-Endpoint -name "Request Password Reset" -url "$baseUrl/api/auth/forgot-password" -method "POST" -body $forgotBody

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Base URL: $baseUrl" -ForegroundColor White
Write-Host "  Test User: $testEmail" -ForegroundColor White
if ($token) {
    Write-Host "  Token: Generated [OK]" -ForegroundColor Green
} else {
    Write-Host "  Token: Not available [FAIL]" -ForegroundColor Red
}
Write-Host ""
