# Perbaikan Prediction di Mobile App

## Masalah yang Diperbaiki
Ketika user klik tombol prediksi di mobile app, terjadi kegagalan karena:

### 1. **URL Endpoint Salah**
- ❌ **Sebelum**: `http://103.151.63.79:5011/predict` (tanpa `/api`)
- ✅ **Sesudah**: `http://103.151.63.79:5011/api/predict`

### 2. **Token Authorization Tidak Dikirim**
- ❌ **Sebelum**: Tidak ada header Authorization
- ✅ **Sesudah**: Menambahkan header `Authorization: Bearer <token>`

### 3. **Nama Key Token Tidak Konsisten**
- ❌ **Sebelum**: Mencari token dengan key `'auth_token'`
- ✅ **Sesudah**: Menggunakan key `'token'` (sesuai dengan AuthService)

### 4. **Format Response Berbeda**
- ❌ **Sebelum**: Mengharapkan response langsung `{prediction, confidence, second_prediction, ...}`
- ✅ **Sesudah**: Handle format baru `{status: 'success', data: {prediction, confidence, top_crops: [...]}}`

## File yang Diubah

### 1. `lib/prediksi.dart`
**Perubahan:**
- Update `_predictUrl` dari `/predict` ke `/api/predict`
- Tambahkan field `String? _authToken`
- Ambil token dari SharedPreferences dengan key `'token'`
- Tambahkan Authorization header di HTTP request
- Update parsing response untuk handle format baru dengan `top_crops` array
- Tambahkan logging untuk debugging
- Handle status 401 untuk token expired

### 2. `lib/constants/app_constants.dart`
**Perubahan:**
- Update `predictUrl` dari `http://localhost:5000/predict` ke `http://localhost:5010/api/predict`

### 3. `lib/services/sensor_service.dart`
**Perubahan:**
- Tambahkan import `shared_preferences`
- Di `PredictionService.predict()`, tambahkan:
  - Ambil token dari SharedPreferences
  - Validasi token tersedia
  - Kirim token di Authorization header

## Testing

### Test di Backend (Sudah Berhasil)
```powershell
.\test-prediction.ps1
```

**Hasil:**
- ✅ Predict dengan custom data: SUCCESS
- ✅ Predict dari sensor terkini: SUCCESS
- ✅ Response format: `{status: 'success', data: {prediction, confidence, top_crops: [...]}}`

### Test di Mobile App
1. **Login** dengan akun yang valid (pastikan dapat token)
2. Pastikan sensor data sudah tersedia (N, P, K > 0)
3. Klik tombol **"Ambil Lokasi"** atau input manual
4. Klik tombol **"Prediksi"**

**Expected Result:**
- ✅ Muncul loading indicator
- ✅ Request dikirim ke `/api/predict` dengan Authorization header
- ✅ Response berhasil dengan status 200
- ✅ Muncul hasil prediksi dengan top crops
- ✅ Snackbar success: "Prediksi berhasil: grapes (38%)"

**Error Handling:**
- Status 401: "Token expired, silakan login kembali"
- Status lain: Menampilkan pesan error dari server
- Network error: "Prediksi gagal: [error message]"

## Cara Debug Mobile App

### 1. Lihat Log Flutter
```bash
flutter logs
```

### 2. Cek Request yang Dikirim
Lihat di log untuk baris:
```
Sending prediction request with body: {N: 350, P: 856, K: 855, ...}
```

### 3. Cek Response
Lihat di log untuk:
```
Prediction response status: 200
Prediction response body: {"status":"success","data":{...}}
```

### 4. Cek Token
Jika muncul error "Silakan login terlebih dahulu":
- Login ulang
- Token akan disimpan dengan key `'token'` di SharedPreferences

## API Endpoint Reference

### POST /api/predict
**Headers:**
```
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "N": 350,
  "P": 856,
  "K": 855,
  "temperature": 35.2,
  "humidity": 26.5,
  "pH": 5.9,
  "altitude": 105.8
}
```

**Response (Success 200):**
```json
{
  "status": "success",
  "data": {
    "prediction": "grapes",
    "confidence": 38,
    "altitude": 105.8,
    "top_crops": [
      {"crop": "grapes", "probability": 38},
      {"crop": "banana", "probability": 18.5},
      {"crop": "chickpea", "probability": 16.5}
    ]
  }
}
```

**Response (Error 401):**
```json
{
  "status": "error",
  "message": "Invalid or expired token"
}
```

## Validasi Backend

Backend memvalidasi:
1. Token harus valid dan tidak expired
2. NPK data: Minimal satu dari N, P, atau K harus > 0
3. Temperature, humidity, pH harus ada (bisa 0)

## Next Steps

Jika masih gagal:
1. Pastikan backend berjalan di `http://103.151.63.79:5011`
2. Test endpoint manual dengan curl/Postman
3. Cek apakah token valid dengan test `/api/auth/profile`
4. Pastikan sensor mengirim data NPK yang valid (> 0)
5. Lihat log backend untuk error details
