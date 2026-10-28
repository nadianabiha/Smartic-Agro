# Smartic Agro V2 — UI rebuild

## Perubahan UI
- Menambahkan halaman awal (welcome) dengan palet hijau muda sesuai referensi.
- Login dan daftar akun ditulis ulang dengan field sederhana, validasi, tombol hijau, dan layout responsif.
- Splash mengarahkan pengguna yang belum login ke halaman awal.
- Dashboard ditata dengan kartu Lahan 1, judul Kondisi Tanah, grid sensor, detail lokasi, aksi prediksi, rekomendasi, serta navigasi Home/Riwayat.
- Halaman Riwayat menggunakan palet visual yang konsisten.
- Alur AuthService, service sensor, prediksi, GPS, dan penyimpanan yang sudah ada tetap dipakai.

## Catatan
- URL API/backend harus disesuaikan dengan cara menjalankan aplikasi (Android emulator biasanya menggunakan `10.0.2.2`, perangkat fisik menggunakan IP LAN komputer).
- Profil lahan tersimpan lokal sampai endpoint sinkronisasi backend tersedia.
- Build/analyzer Flutter perlu dijalankan pada mesin yang memiliki Flutter SDK dan Android SDK.
