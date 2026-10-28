# Test Prediction dengan Data Sensor Terkini

Write-Host "Testing Prediction Endpoint..." -ForegroundColor Cyan
Write-Host ""

# Login dulu untuk dapat token
Write-Host "1. Login untuk mendapatkan token..." -ForegroundColor Yellow
$loginBody = @{
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:5010/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginResponse.data.token

Write-Host "   Token: $($token.Substring(0,20))..." -ForegroundColor Green
Write-Host ""

# Test Predict dengan custom data
Write-Host "2. Testing Predict dengan Custom Data..." -ForegroundColor Yellow
$predictBody = @{
    N = 350
    P = 856
    K = 855
    temperature = 35.2
    humidity = 26.5
    pH = 5.9
    altitude = 105.8
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

try {
    $predictResponse = Invoke-RestMethod -Uri "http://localhost:5010/api/predict" -Method Post -Body $predictBody -Headers $headers
    Write-Host "   [OK] Prediction berhasil!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Result:" -ForegroundColor Cyan
    $predictResponse | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "   [FAIL] Prediction gagal!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "3. Testing Predict from Latest Sensor..." -ForegroundColor Yellow

try {
    $latestResponse = Invoke-RestMethod -Uri "http://localhost:5010/api/predict/latest" -Method Get -Headers $headers
    Write-Host "   [OK] Prediction dari sensor berhasil!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Result:" -ForegroundColor Cyan
    $latestResponse | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "   [FAIL] Prediction dari sensor gagal!" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Testing Complete!" -ForegroundColor Cyan
