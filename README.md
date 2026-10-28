# Smartic Agro V2 — Smart Crop Prediction System 🌾

Sistem prediksi tanaman cerdas berbasis IoT dan Machine Learning untuk membantu petani memilih tanaman yang tepat berdasarkan kondisi tanah dan lingkungan.

## 📋 Deskripsi Project

Smart Crop Prediction adalah aplikasi mobile yang terintegrasi dengan sensor IoT untuk mengumpulkan data kondisi tanah (N, P, K, pH, suhu, kelembaban) secara real-time dan menggunakan Machine Learning untuk merekomendasikan jenis tanaman yang paling sesuai.

## 🏗️ Struktur Project

```
proyek-mandiri-smarticagro/
├── backend/                # Node.js Express API Server
│   ├── src/               # Source code backend
│   │   ├── controllers/   # Route controllers
│   │   ├── models/        # Database models
│   │   ├── routes/        # API routes
│   │   ├── services/      # Business logic
│   │   └── middleware/    # Express middleware
│   ├── ml-service/        # Python ML prediction service
│   │   └── predict.py     # ML model inference
│   └── database/          # Database schemas & migrations
│
└── frontend-mobile/       # Flutter Mobile Application
    ├── lib/
    │   ├── pages/         # UI screens
    │   ├── widgets/       # Reusable widgets
    │   ├── services/      # API & business logic
    │   ├── models/        # Data models
    │   ├── constants/     # App constants
    │   └── utils/         # Utilities
    └── assets/            # Images, fonts, etc.
```

## 🚀 Tech Stack

### Backend
- **Runtime**: Node.js v22.20.0
- **Framework**: Express.js
- **Database**: PostgreSQL 18
- **MQTT Broker**: Mosquitto (sensor data streaming)
- **ML Engine**: Python 3.x + scikit-learn
- **Authentication**: JWT (JSON Web Token)
- **Email**: Nodemailer + Gmail SMTP

### Frontend Mobile
- **Framework**: Flutter SDK ≥ 3.5.3
- **State Management**: StatefulWidget
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences
- **Location**: geolocator + permission_handler
- **UI**: Material Design 3

### IoT Sensors
- Nitrogen (N) sensor
- Phosphorus (P) sensor
- Potassium (K) sensor
- Soil pH sensor
- Temperature sensor
- Humidity sensor

## 📦 Prerequisites

### Backend
- Node.js v22+ 
- PostgreSQL 18+ (running on port 5433)
- Python 3.8+
- pip (Python package manager)

### Frontend
- Flutter SDK ≥ 3.5.3
- Dart SDK ≥ 3.5.3
- Android Studio / VS Code
- Chrome browser (untuk testing web)

## 🔧 Installation

### 1. Clone Repository

```bash
git clone https://github.com/IET-Polinela/proyek-mandiri-smarticagro.git
cd proyek-mandiri-smarticagro
```

### 2. Setup Backend

```bash
cd backend

# Install dependencies
npm install

# Install Python dependencies
pip install -r requirements.txt

# Setup environment variables
cp .env.example .env
# Edit .env dengan konfigurasi Anda

# Setup database
node database/migrate.js

# Run server
node src/server.js
```

**Environment Variables (.env):**
```env
# Database
DB_HOST=localhost
DB_PORT=5433
DB_NAME=sensor_db
DB_USER=postgres
DB_PASSWORD=your_password

# MQTT
MQTT_BROKER=your_mqtt_broker_ip
MQTT_PORT=1882
MQTT_TOPIC=sensor/final

# Server
SERVER_HOST=0.0.0.0
SERVER_PORT=5010

# JWT
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=24h

# Email (Gmail)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password
```

### 3. Setup Frontend Mobile

```bash
cd frontend-mobile

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

## 🎯 Features

### ✅ Implemented Features

#### Authentication
- ✅ User Registration dengan email verification
- ✅ Login dengan JWT authentication
- ✅ Forgot Password dengan email reset code
- ✅ Profile management

#### Dashboard
- ✅ Real-time sensor monitoring (auto-refresh 5 detik)
- ✅ Display data N, P, K, pH, suhu, kelembaban
- ✅ GPS location tracking
- ✅ MQTT connection status indicator
- ✅ Responsive UI untuk semua ukuran layar

#### Prediction
- ✅ Crop recommendation berdasarkan sensor data
- ✅ Confidence score untuk setiap rekomendasi
- ✅ Top 3 tanaman terbaik
- ✅ Konfetti animation untuk hasil prediksi
- ✅ Manual input prediction (optional)

#### History
- ✅ Local storage dengan SharedPreferences
- ✅ List semua prediksi sebelumnya
- ✅ Export to CSV
- ✅ Clear history

### 🔄 Ongoing / Future Features
- 🔄 ML Model rebuild (saat ini corrupt)
- 🔄 Push notifications
- 🔄 Weather API integration
- 🔄 Multi-language support (ID/EN)
- 🔄 Dark mode

## 🌐 API Endpoints

### Authentication
```
POST /api/auth/register      - Register user baru
POST /api/auth/login         - Login user
POST /api/auth/forgot-password - Request reset code
POST /api/auth/verify-code   - Verify reset code
POST /api/auth/reset-password - Reset password
GET  /api/auth/profile       - Get user profile (requires token)
```

### Sensor Data
```
GET /api/sensor/latest       - Get latest sensor readings
GET /api/health              - Health check endpoint
```

### Prediction
```
POST /api/predict            - Predict crop (requires token)
GET  /api/predict/latest     - Get latest prediction (requires token)
```

## 📱 Mobile App Screens

1. **Login Page** - Authentication dengan email & password
2. **Register Page** - User registration
3. **Forgot Password** - Password recovery
4. **Dashboard** - Main screen dengan sensor monitoring
5. **Prediction Result** - Crop recommendation display
6. **History** - Prediction history list

## 🗄️ Database Schema

### Users Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    reset_code VARCHAR(6),
    reset_code_expires TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### Sensor Data (via MQTT, not stored)
```json
{
  "N": 90.0,
  "P": 42.0,
  "K": 43.0,
  "temperature": 20.8,
  "humidity": 82.0,
  "pH": 6.5
}
```

## 🔐 Security

- JWT token-based authentication
- Password hashing dengan bcrypt (10 rounds)
- Email verification untuk password reset
- Rate limiting untuk API endpoints
- CORS configured untuk localhost development

## 🐛 Known Issues

1. **ML Model Corrupt**: crop_model_bundle.pkl perlu rebuild dengan proper sklearn import
2. **Port 5433**: PostgreSQL menggunakan port 5433 (bukan default 5432)
3. **Scroll position**: Saat auto-refresh, scroll position tetap maintained

## 📝 Development Notes

### Backend
- Server berjalan di `http://localhost:5010`
- ML prediction service di `/api/predict`
- MQTT broker untuk real-time sensor data
- Email service untuk password reset

### Frontend
- Localhost API: `http://localhost:5010/api`
- Auto-refresh sensor data setiap 5 detik
- Responsive design untuk mobile & web
- State management dengan StatefulWidget

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is developed for educational purposes.

## 👥 Team

**IET Polinela** - Politeknik Negeri Lampung

## 📞 Contact

Project Link: [https://github.com/IET-Polinela/proyek-mandiri-smarticagro](https://github.com/IET-Polinela/proyek-mandiri-smarticagro)

---

⭐ **Star this repository if you find it helpful!** ⭐


## Smartic Agro V2 (pengembangan)

- Versi aplikasi Flutter diperbarui menjadi `2.0.0+2`.
- Tambahan halaman **Detail Kondisi Lahan** untuk pencatatan N, P, K, pH, suhu, kelembapan, EC, lokasi, dan catatan survei.
- Profil lahan disimpan lokal di perangkat; sinkronisasi dan rekomendasi yang benar-benar menggunakan dataset tanah lokal masih memerlukan pengembangan backend/model V2.
- URL backend dapat dikonfigurasi lewat `--dart-define=SMARTIC_API_URL=...`.

Baca `SMARTIC_AGRO_V2_STATUS.md` untuk langkah menjalankan APK dan daftar pekerjaan V2 yang masih perlu diselesaikan.

## Pengembangan lanjutan V2 (ditambahkan)
- Halaman Riwayat Profil Lahan membaca hingga 100 catatan yang disimpan lokal; catatan dapat dibuka dan dihapus.
- Form profil lahan kini dapat mengambil koordinat GPS perangkat. Izin lokasi Android sudah ditambahkan ke manifest.
- Pipeline pelatihan kandidat model tanah lokal tersedia di `backend/ml-service/train_local_soil_model.py`, beserta format data dan panduan evaluasi di `backend/ml-service/LOCAL_SOIL_V2.md`.
- ML service kini membaca `feature_columns` dari bundle model bila tersedia, sehingga bundle kandidat dengan fitur EC dapat dipakai tanpa memutus kompatibilitas bundle enam fitur lama.

**Batasan saat ini:** profil lahan masih tersimpan lokal pada perangkat, belum disinkronkan ke database/backend. Tidak ada dataset tanah lokal berlabel yang disertakan, jadi model kandidat V2 belum dilatih dan model aktif tidak diganti. Build APK dan analisis Flutter harus dijalankan di lingkungan yang memiliki Flutter SDK/Android SDK.
