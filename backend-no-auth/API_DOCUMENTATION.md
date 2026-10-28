# Dokumentasi API Backend SmartIcAgro

Base URL: `http://localhost:5010`

## Daftar Isi
- [Autentikasi](#autentikasi)
- [Data Sensor](#data-sensor)
- [Prediksi](#prediksi)
- [Daftar API Tersedia](#daftar-api-tersedia)

---

## Autentikasi

### 1. Registrasi User
**Endpoint:** `POST /api/auth/register`

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (Sukses):**
```json
{
  "status": "success",
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

---

### 2. Login
**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (Sukses):**
```json
{
  "status": "success",
  "message": "Login berhasil",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 3. Dapatkan Profile
**Endpoint:** `GET /api/auth/profile`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (Sukses):**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2026-01-03T10:00:00.000Z"
    }
  }
}
```

---

## Data Sensor

### 1. Dapatkan Data Sensor Terbaru
**Endpoint:** `GET /api/sensor/latest`

**Response (Sukses):**
```json
{
  "status": "success",
  "data": {
    "N": 90.5,
    "P": 42.3,
    "K": 43.1,
    "temperature": 28.5,
    "humidity": 82.0,
    "pH": 6.5,
    "ec": 1.2,
    "timestamp": "2026-01-03T10:30:00.000Z",
    "status_mqtt": "CONNECTED"
  }
}
```

**Response (MQTT Terputus):**
```json
{
  "status": "success",
  "data": {
    "N": 0,
    "P": 0,
    "K": 0,
    "temperature": 0,
    "humidity": 0,
    "pH": 0,
    "ec": 0,
    "timestamp": null,
    "status_mqtt": "DISCONNECTED"
  }
}
```

---

### 2. Cek Kesehatan API
**Endpoint:** `GET /api/health`

**Response:**
```json
{
  "status": "success",
  "message": "API is running",
  "mqtt_status": "CONNECTED",
  "timestamp": "2026-01-03T10:30:00.000Z"
}
```

---

## Prediksi

### 1. Prediksi Tanaman (Data Custom)
**Endpoint:** `POST /api/predict`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "N": 90,
  "P": 42,
  "K": 43,
  "temperature": 28,
  "humidity": 82,
  "pH": 6.5,
  "altitude": 100
}
```

**Parameter:**
- `N` (number, wajib): Level Nitrogen
- `P` (number, wajib): Level Phosphorus
- `K` (number, wajib): Level Potassium
- `temperature` (number, wajib): Suhu dalam Celsius
- `humidity` (number, wajib): Persentase kelembaban
- `pH` (number, wajib): Level pH tanah
- `altitude` (number, opsional): Ketinggian dalam meter (default: 0)

**Response (Sukses):**
```json
{
  "status": "success",
  "data": {
    "altitude": 100,
    "prediction": "rice",
    "confidence": 91.0,
    "top_crops": [
      {
        "crop": "rice",
        "probability": 91.0
      },
      {
        "crop": "jute",
        "probability": 9.0
      },
      {
        "crop": "banana",
        "probability": 5.5
      }
    ]
  }
}
```

**Contoh dengan cURL:**
```bash
curl -X POST http://localhost:5010/api/predict \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "N": 90,
    "P": 42,
    "K": 43,
    "temperature": 28,
    "humidity": 82,
    "pH": 6.5,
    "altitude": 100
  }'
```

**Contoh dengan PowerShell:**
```powershell
$token = "your_token_here"
$headers = @{Authorization="Bearer $token"}
$body = @{
  N=90
  P=42
  K=43
  temperature=28
  humidity=82
  pH=6.5
  altitude=100
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://localhost:5010/api/predict' `
  -Method POST `
  -Body $body `
  -ContentType 'application/json' `
  -Headers $headers
```

---

### 2. Prediksi dari Data Sensor Terbaru
**Endpoint:** `GET /api/predict/latest`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `altitude` (number, opsional): Ketinggian dalam meter (default: 0)

**Contoh:**
```
GET /api/predict/latest?altitude=500
```

**Response (Sukses):**
```json
{
  "status": "success",
  "data": {
    "altitude": 500,
    "prediction": "coffee",
    "confidence": 78.5,
    "top_crops": [
      {
        "crop": "coffee",
        "probability": 78.5
      },
      {
        "crop": "orange",
        "probability": 15.2
      },
      {
        "crop": "pomegranate",
        "probability": 6.3
      }
    ]
  },
  "sensor_data": {
    "N": 90.5,
    "P": 42.3,
    "K": 43.1,
    "temperature": 22.5,
    "humidity": 75.0,
    "pH": 6.2,
    "ec": 1.2,
    "timestamp": "2026-01-03T10:30:00.000Z"
  }
}
```

**Response (Tidak Ada Data Sensor):**
```json
{
  "status": "error",
  "message": "No valid sensor data available. All values are zero."
}
```

**Response (MQTT Terputus):**
```json
{
  "status": "error",
  "message": "MQTT not connected. Cannot get sensor data."
}
```

**Contoh dengan cURL:**
```bash
curl -X GET "http://localhost:5010/api/predict/latest?altitude=500" \
  -H "Authorization: Bearer <token>"
```

**Contoh dengan PowerShell:**
```powershell
$token = "your_token_here"
$headers = @{Authorization="Bearer $token"}

Invoke-RestMethod -Uri 'http://localhost:5010/api/predict/latest?altitude=500' `
  -Method GET `
  -Headers $headers
```

---

## Response Error

### 400 Bad Request
```json
{
  "status": "error",
  "message": "Missing required fields: N, P, K"
}
```

### 401 Unauthorized
```json
{
  "status": "error",
  "message": "No token provided"
}
```

### 404 Not Found
```json
{
  "status": "error",
  "message": "Endpoint not found"
}
```

### 500 Internal Server Error
```json
{
  "status": "error",
  "message": "Prediction failed. Please check if Python and required packages are installed."
}
```

---

## Tanaman yang Didukung

Sistem prediksi dapat mengidentifikasi tanaman berikut berdasarkan kondisi tanah dan ketinggian:

1. apple
2. banana
3. blackgram
4. chickpea
5. coconut
6. coffee
7. cotton
8. grapes
9. jute
10. kidneybeans
11. lentil
12. maize
13. mango
14. mothbeans
15. mungbean
16. muskmelon
17. orange
18. papaya
19. pigeonpeas
20. pomegranate
21. rice
22. watermelon

---

## Aturan Ketinggian

Sistem memfilter rekomendasi tanaman berdasarkan kesesuaian ketinggian:

| Tanaman | Ketinggian Min (m) | Ketinggian Max (m) |
|---------|--------------------|--------------------|
| apple | 1000 | 2500 |
| banana | 0 | 1000 |
| coconut | 0 | 600 |
| coffee | 600 | 1800 |
| rice | 0 | 2000 |
| watermelon | 0 | 600 |
| ... | ... | ... |

---

## Catatan

- Semua endpoint yang memerlukan autentikasi membutuhkan token JWT valid di header `Authorization`
- Format token: `Bearer <token>`
- Token kadaluarsa setelah 24 jam
- Sistem prediksi menggunakan pendekatan hybrid: Model ML + filtering berbasis aturan ketinggian
- Filtering ketinggian memastikan hanya tanaman yang cocok untuk elevasi tertentu yang direkomendasikan

---

## Daftar API Tersedia

### Autentikasi
| Method | Endpoint | Deskripsi | Auth Required |
|--------|----------|-----------|---------------|
| POST | `/api/auth/register` | Registrasi user baru | ❌ |
| POST | `/api/auth/login` | Login user | ❌ |
| GET | `/api/auth/profile` | Dapatkan profile user | ✅ |

### Data Sensor
| Method | Endpoint | Deskripsi | Auth Required |
|--------|----------|-----------|---------------|
| GET | `/api/sensor/latest` | Dapatkan data sensor terbaru dari MQTT | ❌ |
| GET | `/api/health` | Cek status kesehatan API dan MQTT | ❌ |

### Prediksi Tanaman
| Method | Endpoint | Deskripsi | Auth Required |
|--------|----------|-----------|---------------|
| POST | `/api/predict` | Prediksi tanaman dengan data custom (N, P, K, temperature, humidity, pH, altitude) | ✅ |
| GET | `/api/predict/latest` | Prediksi tanaman menggunakan data sensor terbaru (dengan parameter altitude opsional) | ✅ |

### Parameter Prediksi
**Wajib:**
- `N` - Level Nitrogen
- `P` - Level Phosphorus
- `K` - Level Potassium
- `temperature` - Suhu (°C)
- `humidity` - Kelembaban (%)
- `pH` - pH Tanah

**Opsional:**
- `altitude` - Ketinggian (meter, default: 0)

### Cara Mendapatkan Token
1. Registrasi user dengan `POST /api/auth/register`
2. Login dengan `POST /api/auth/login`
3. Gunakan token dari response login di header: `Authorization: Bearer <token>`
4. Token berlaku selama 24 jam

### Contoh Workflow
```
1. Registrasi → POST /api/auth/register
2. Login → POST /api/auth/login (dapatkan token)
3. Cek sensor → GET /api/sensor/latest
4. Prediksi → POST /api/predict atau GET /api/predict/latest?altitude=500
```
