# Smartic Agro V2 — baseline mobile project

Project ini dibuat dari kode dasar Smartic Agro yang diberikan, dengan perubahan awal untuk menyiapkan V2.

## Perubahan yang sudah dibuat
- Versi Flutter dinaikkan ke `2.0.0+2`.
- Branding aplikasi dan splash screen menjadi **Smartic Agro V2**.
- URL backend kini bisa diatur saat menjalankan/build melalui `SMARTIC_API_URL`, sehingga tidak perlu mengedit source saat pindah dari server lama ke backend lokal.
- Struktur autentikasi, dashboard sensor, GPS, riwayat lokal, WebSocket, dan prediksi dari project dasar dipertahankan.
- File `.git`, file environment produksi, dan file akun/rahasia tidak disertakan dalam paket ini.

## Menjalankan di Android
1. Ekstrak ZIP.
2. Buka terminal di `frontend-mobile`.
3. Jalankan `flutter pub get`.
4. Sambungkan HP Android dengan USB debugging aktif atau nyalakan emulator Android Studio.
5. Pastikan `flutter devices` menampilkan perangkat.
6. Jalankan, sesuaikan alamat backend:
   - Emulator Android: `flutter run --dart-define=SMARTIC_API_URL=http://10.0.2.2:5010`
   - HP fisik: gunakan IP LAN laptop, misalnya `flutter run --dart-define=SMARTIC_API_URL=http://192.168.1.10:5010`
   - Server lama: `flutter run`
7. Membuat APK: `flutter build apk --release --dart-define=SMARTIC_API_URL=http://IP_BACKEND:5010`

> `IP_BACKEND` harus diganti dengan alamat backend yang benar. Emulator menggunakan `10.0.2.2` untuk mengakses localhost komputer host; HP fisik menggunakan IP LAN komputer dan keduanya harus satu jaringan.

## Status V2 saat ini
Ini adalah **baseline V2**, bukan klaim bahwa semua fitur baru sudah selesai. Fitur aplikasi lama masih menjadi fondasi. Hal yang masih perlu dikembangkan dan diuji:
- Dashboard khusus V2 untuk lahan dan sensor N, P, K, pH, suhu, kelembapan, serta EC.
- Detail profil lahan dengan GPS, waktu pengukuran, dan sumber data sensor/manual.
- Histori pengukuran dan rekomendasi yang menyimpan snapshot data lahan.
- Dataset tanah lokal yang tervalidasi dan pipeline training/evaluasi model.
- Pembaruan endpoint/backend untuk mengirim data profil lahan dan rekomendasi V2.
- Uji integrasi sensor NPK 7-in-1/ESP32, MQTT, autentikasi, dan APK pada perangkat Android.

## Catatan penting tentang model AI
Kode model lama memuat `crop_model_bundle.joblib`, tetapi paket sumber yang diterima tidak menyertakan dataset lokal V2 untuk training. Jangan menyatakan model sebagai model tanah lokal atau mengklaim akurasi V2 sebelum dataset yang benar dipakai untuk training dan evaluasi. Dataset V2 harus disiapkan terpisah dengan kolom fitur, label tanaman, sumber data, lokasi/jenis tanah, serta aturan validasi yang terdokumentasi.

## Pengembangan lanjutan
- Form profil lahan mendukung pengambilan koordinat GPS (izin Android ditambahkan).
- Riwayat profil lahan lokal dapat dibuka, diperluas untuk melihat parameter, dan dihapus.
- Pipeline pelatihan kandidat model lokal dibuat dengan pemeriksaan kolom, holdout test, accuracy, macro-F1, laporan per kelas, dan gerbang minimum macro-F1.
- ML service mendukung daftar fitur yang tersimpan pada bundle model termasuk EC; bundle model lama enam fitur tetap didukung.
- Belum ada dataset lokal berlabel, sehingga belum ada angka akurasi V2 dan belum ada model V2 yang diklaim siap produksi.
