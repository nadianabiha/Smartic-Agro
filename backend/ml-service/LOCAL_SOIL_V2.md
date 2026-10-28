# Pipeline Dataset Tanah Lokal — Smartic Agro V2

## Format dataset
Gunakan CSV UTF-8 dengan kolom:

- Wajib: `N`, `P`, `K`, `temperature`, `humidity`, `pH`, `crop`
- Opsional: `ec` (wajib terisi pada semua baris bila dipakai sebagai fitur model)

`crop` harus berisi label tanaman yang benar-benar diketahui dari catatan lapangan/label agronomis, bukan hasil prediksi model. Sertakan kolom metadata tambahan pada file sumber terpisah bila dibutuhkan (kode sampel, tanggal, kabupaten, jenis tanah, sumber pengukuran, alat, petugas, dan catatan kalibrasi); jangan jadikan ID atau lokasi sebagai fitur model tanpa justifikasi.

## Melatih kandidat model

Dari folder `backend/ml-service`:

```bash
python -m pip install -r requirements.txt
python train_local_soil_model.py data/dataset_tanah_lokal.csv
```

Script membuat `models/crop_model_bundle_local_candidate.joblib` dan file `.metrics.json`. Model kandidat hanya disimpan jika macro-F1 memenuhi ambang default 0,65. Ambang ini adalah gerbang teknis awal, bukan bukti kelayakan agronomis. Untuk mengubahnya, gunakan `--min-macro-f1` dan dokumentasikan alasan.

Untuk model yang memakai EC, semua baris harus memiliki nilai EC. Saat model kandidat berfitur EC digunakan, permintaan prediksi harus menyertakan `ec`; model lama enam fitur tetap kompatibel.

## Validasi sebelum deployment

1. Pastikan satuan N/P/K konsisten dan nilai sensor sudah dikalibrasi.
2. Periksa duplikasi sampel dan kebocoran data (sampel dari lokasi/waktu sama jangan tersebar ke train dan test tanpa pertimbangan).
3. Lakukan evaluasi terpisah berdasarkan lokasi atau waktu bila dataset memungkinkan; random holdout saja bisa terlalu optimistis.
4. Tinjau precision/recall per tanaman, confusion matrix, macro-F1, jumlah sampel tiap label, dan rentang input.
5. Bandingkan prediksi dengan ahli/hasil budidaya di lapangan. Jangan menyatakan akurasi V2 sebelum evaluasi dan pengujian lapangan dilakukan.
6. Setelah disetujui, backup bundle lama lalu deploy kandidat secara eksplisit sebagai `models/crop_model_bundle.joblib`. Jangan menimpa otomatis.

Template kosong tersedia di `data/templates/dataset_tanah_lokal_template.csv`. Template ini bukan dataset latih dan tidak dapat menghasilkan model.
