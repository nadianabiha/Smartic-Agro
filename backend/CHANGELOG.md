# Changelog & Pembaruan Arsitektur

Dokumen ini mencatat seluruh pembaruan keamanan, performa, dan arsitektur yang baru saja diterapkan pada backend SmartICAgro.

## 1. Peningkatan Keamanan (Security)
- **Patch Kerentanan NPM:** Melakukan update dependensi melalui `npm audit fix` untuk menambal 16 kerentanan (vulnerabilities) yang ditemukan oleh GitHub Dependabot.
- **Proteksi HTTP Header:** Mengimplementasikan library `helmet` pada `src/app.js` untuk melindungi aplikasi dari serangan *Cross-Site Scripting (XSS)*, *Clickjacking*, dan ancaman web lainnya.
- **Pembatasan Request (Rate Limiting):** Mengimplementasikan `express-rate-limit` untuk membatasi maksimal 100 *request* per 15 menit dari satu IP, guna mencegah serangan *Brute Force* dan *DDoS* pada API.
- **Validasi Kunci Rahasia:** Menambahkan pengecekan *fatal error* pada `src/config/auth.config.js` untuk memastikan bahwa di mode produksi (`NODE_ENV=production`), server tidak akan bisa menyala jika `JWT_SECRET` lupa tidak diatur.

## 2. Peningkatan Performa & Arsitektur (Microservices)
- **Pemisahan ML Service (FastAPI):**
  - **Masalah Sebelumnya:** Prediksi berjalan menggunakan `python-shell` dari dalam Node.js. Setiap kali *request* datang, *shell* Python akan menyala dari awal, memuat ulang model *Machine Learning*, dan memakan waktu eksekusi yang lambat (dalam skala detik).
  - **Solusi Baru:** Model ML dipisahkan menjadi sebuah kontainer *microservice* tersendiri yang dibangun menggunakan **FastAPI**. Model hanya dimuat (loaded ke RAM) satu kali saat server menyala. Node.js kini memanggil ML Service melalui HTTP Request menggunakan `axios`. Waktu prediksi kini jauh lebih responsif (dalam skala milidetik).
- **Efisiensi Docker Image Backend:**
  - `Dockerfile` untuk backend Node.js telah dirombak. Seluruh instalasi paket sistem Python (seperti `python3`, `py3-pip`, `py3-numpy`, dsb.) telah dihapus. Hal ini membuat ukuran *image* Node.js menjadi sangat ringan dan proses *build* menjadi lebih cepat.
  - Sebuah `Dockerfile` baru khusus diciptakan di dalam folder `ml-service/` untuk membungkus kode Python.

## 3. Integrasi MQTT Mandiri (All-in-One Docker)
- **Menambahkan Eclipse Mosquitto:**
  - Sebelumnya, aplikasi mengandalkan server MQTT eksternal (di IP `103.151.63.77`).
  - Kini, server *broker* MQTT lokal (Mosquitto) telah diintegrasikan langsung ke dalam `docker-compose.yml`.
  - Node.js backend telah dikonfigurasi agar tersambung secara mulus ke MQTT *container* melalui *internal network* Docker.
  - Untuk perangkat IoT (seperti ESP32) di lapangan, koneksi dikaitkan ke _host port_ `1883`, yang akan otomatis di-*forward* ke Mosquitto di dalam Docker. Tidak perlu mengubah *script* pada perangkat keras IoT, selama mengarah ke *port* tersebut.

---
*Dokumentasi ini di-*generate* untuk membantu pengembang lain dan mempermudah deployment sistem SmartICAgro di masa depan.*
