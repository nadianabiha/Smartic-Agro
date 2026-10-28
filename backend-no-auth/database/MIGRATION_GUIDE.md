# 📚 Migration Guide

## Cara Menggunakan Sistem Migrasi

### 1. Jalankan Migrasi (Migrate Up)
Untuk membuat semua tabel dan menjalankan migrasi yang belum dieksekusi:

```bash
cd backend
node database/migrator.js up
```

atau cukup:

```bash
node database/migrator.js
```

### 2. Rollback Migrasi (Migrate Down)
Untuk membatalkan migrasi terakhir:

```bash
node database/migrator.js down
```

### 3. Cek Status Migrasi
Untuk melihat migrasi mana yang sudah/belum dijalankan:

```bash
node database/migrator.js status
```

## 📋 Daftar Migrasi

1. **001_create_users_table.js** - Membuat tabel users dan index-nya
2. **002_create_sensor_data_table.js** - Membuat tabel sensor_data dan index-nya
3. **003_add_reset_password_columns.js** - Menambah kolom reset password

## 🆕 Membuat Migrasi Baru

1. Buat file baru di folder `migrations/` dengan format:
   ```
   00X_nama_migrasi.js
   ```

2. Gunakan template berikut:

```javascript
/**
 * Migration: Deskripsi migrasi
 * Created: YYYY-MM-DD
 */

module.exports = {
    async up(client) {
        console.log('  📋 Running migration...');
        
        // SQL untuk membuat/mengubah schema
        await client.query(`
            -- SQL code here
        `);

        console.log('  ✅ Migration completed');
    },

    async down(client) {
        console.log('  📋 Rolling back migration...');
        
        // SQL untuk membatalkan perubahan
        await client.query(`
            -- Rollback SQL here
        `);
        
        console.log('  ✅ Rollback completed');
    }
};
```

## ⚠️ Best Practices

1. **Jangan Edit Migrasi yang Sudah Dijalankan** - Buat migrasi baru untuk perubahan
2. **Test Rollback** - Pastikan fungsi `down()` bekerja dengan baik
3. **Atomic Changes** - Satu migrasi untuk satu perubahan logis
4. **Backup Database** - Selalu backup sebelum migrasi di production
5. **Naming Convention** - Gunakan naming yang deskriptif dan berurutan

## 🔄 Workflow Development

### Setup Awal
```bash
# 1. Pastikan database sudah dibuat
# 2. Configure .env
# 3. Run migrations
node database/migrator.js up
```

### Menambah Fitur Baru
```bash
# 1. Buat migration file baru
# 2. Tulis up() dan down()
# 3. Test migration
node database/migrator.js up

# 4. Test rollback
node database/migrator.js down

# 5. Jika OK, commit ke git
```

## 🚨 Troubleshooting

### Migration Gagal
Jika migrasi gagal, sistem akan otomatis rollback dan error message akan ditampilkan.

### Reset Semua Migrasi
⚠️ **DANGER: Akan menghapus semua data!**

```sql
-- Di psql atau pgAdmin
DROP TABLE migrations CASCADE;
DROP TABLE users CASCADE;
DROP TABLE sensor_data CASCADE;

-- Kemudian run migrations lagi
node database/migrator.js up
```

### Cek Migrasi yang Sudah Dijalankan
```sql
SELECT * FROM migrations ORDER BY executed_at;
```

## 📊 Migration Tracking

Sistem ini otomatis membuat tabel `migrations` untuk tracking:

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| name | VARCHAR(255) | Nama file migrasi |
| executed_at | TIMESTAMP | Waktu eksekusi |

## 🔐 Production Deployment

```bash
# 1. Backup database
pg_dump sensor_db > backup.sql

# 2. Test migrations di staging
node database/migrator.js status
node database/migrator.js up

# 3. Jika sukses, deploy ke production
# 4. Run migrations di production
node database/migrator.js up
```
