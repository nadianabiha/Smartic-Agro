# Frontend Mobile - Smart Crop Prediction

Flutter aplikasi untuk monitoring sensor dan prediksi tanaman berdasarkan kondisi tanah.

## 📁 Struktur Project (Modular)

```
lib/
├── main.dart                          # Entry point aplikasi
├── config/
│   └── api_config.dart               # API endpoints configuration
├── constants/
│   └── app_constants.dart            # App constants (colors, configs)
├── models/
│   └── prediction_models.dart        # Data models (SensorData, PredictionResult, etc)
├── services/
│   ├── auth_service.dart             # Authentication API
│   ├── sensor_service.dart           # Sensor & Prediction API
│   ├── location_service.dart         # GPS & Location services
│   └── storage_service.dart          # Local storage & history
├── pages/
│   ├── login_page.dart               # Halaman login
│   ├── register_page.dart            # Halaman register
│   ├── forgot_password_page.dart     # Halaman lupa password
│   └── dashboard_page.dart           # Halaman dashboard utama
└── widgets/
    ├── sensor_card.dart              # Card untuk sensor individual
    ├── sensor_monitoring_widget.dart # Widget monitoring sensor real-time
    ├── prediction_result_card.dart   # Card hasil prediksi
    └── history_widget.dart           # Widget riwayat prediksi
```

## 🎯 Fitur Utama

### 1. Authentication
- ✅ Login dengan email & password
- ✅ Register akun baru
- ✅ Forgot password (email verification)
- ✅ Auto-login dengan JWT token
- ✅ Logout

### 2. Sensor Monitoring
- ✅ Real-time data dari MQTT broker (via Node.js API)
- ✅ Auto-refresh setiap 5 detik
- ✅ Display: N, P, K, Suhu, Kelembaban, pH
- ✅ Connection status indicator
- ✅ Manual refresh

### 3. Crop Prediction
- ✅ Predict berdasarkan data sensor
- ✅ Tampilkan top 5 rekomendasi tanaman
- ✅ Confidence score
- ✅ Confetti animation saat sukses

### 4. History Management
- ✅ Simpan riwayat prediksi
- ✅ View detail history
- ✅ Export ke CSV
- ✅ Clear history

### 5. Location Services
- ✅ Request GPS permission
- ✅ Get current location
- ✅ Manual location input

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK ≥ 3.5.3
- Dart SDK ≥ 3.5.3
- Android Studio / VS Code
- Device atau Emulator

### Installation

1. **Clone repository**
```bash
git clone <repo-url>
cd frontend-mobile
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Konfigurasi API**
Edit `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://your-server:5010/api';
```

4. **Run aplikasi**
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d chrome
flutter run -d windows
```

## 🔧 Konfigurasi

### API Endpoints (config/api_config.dart)
```dart
static const String baseUrl = 'http://103.151.63.79:5010/api';
static const String sensorLatest = '$baseUrl/sensor/latest';
static const String predict = '$baseUrl/predict';
```

### App Constants (constants/app_constants.dart)
```dart
static const Duration pollInterval = Duration(seconds: 5);
static const int maxFailedAttempts = 3;
```

### Colors
```dart
AppColors.primary       // #0D7377 (Teal)
AppColors.accent        // #0FA3B1 (Bright Teal)
AppColors.success       // #27AE60 (Green)
AppColors.warning       // #F39C12 (Orange)
AppColors.error         // #E74C3C (Red)
```

## 📦 Dependencies

```yaml
dependencies:
  http: ^1.1.0                  # HTTP requests
  shared_preferences: ^2.2.2    # Local storage
  confetti: ^0.7.0              # Confetti animation
  geolocator: 10.1.0            # GPS location
  permission_handler: ^11.3.1   # Permissions
```

## 🏗️ Arsitektur

### Service Layer
- **AuthService**: Handle login, register, logout
- **SensorService**: Fetch sensor data dari API
- **PredictionService**: Kirim request prediksi
- **LocationService**: GPS & permissions
- **StorageService**: Save/load history

### Model Layer
- **SensorData**: Model data sensor (N, P, K, temp, etc)
- **PredictionResult**: Result dari API prediksi
- **PredictionHistory**: History dengan timestamp

### Widget Layer (Reusable)
- **SensorCard**: Card untuk 1 sensor
- **SensorMonitoringWidget**: Grid semua sensor
- **PredictionResultCard**: Display hasil prediksi
- **HistoryWidget**: List history dengan actions

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs per ABI
flutter build apk --split-per-abi
```

## 🐛 Troubleshooting

### Sensor data tidak muncul
- Cek backend Node.js sudah running
- Cek MQTT broker connected
- Verify API endpoint di `api_config.dart`

### Prediction gagal
- Cek model ML sudah di-load di backend
- Cek API prediction endpoint
- Lihat console log untuk error detail

### Permission denied (Location)
- Enable GPS di device
- Grant location permission saat diminta
- Untuk Android, cek AndroidManifest.xml

## 📝 Notes

- **prediksi.dart SUDAH DIHAPUS** - diganti dengan structure modular
- Semua logic dipecah ke services & widgets
- Lebih mudah di-maintain dan di-test
- Follow Flutter best practices

## 👥 Kontributor

- Development: [Your Name]
- Backend API: Node.js Express
- ML Model: Python scikit-learn

## 📄 License

MIT License
