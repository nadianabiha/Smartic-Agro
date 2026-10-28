# Setup Email untuk Forgot Password

## 1. Gunakan Gmail App Password

Untuk keamanan, Gmail menggunakan App Password bukan password asli.

### Langkah-langkah:

1. **Buka Google Account Settings**
   - Ke https://myaccount.google.com/security

2. **Enable 2-Step Verification**
   - Jika belum aktif, aktifkan dulu 2-Step Verification

3. **Generate App Password**
   - Ke https://myaccount.google.com/apppasswords
   - Pilih "Mail" dan "Other (Custom name)"
   - Beri nama: "Sensor Backend"
   - Click "Generate"
   - Copy 16-digit password yang muncul

4. **Update .env**
   ```env
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASSWORD=generated_app_password_16_digits
   EMAIL_FROM=Sensor App <your_email@gmail.com>
   ```

## 2. Test Email Service

Gunakan endpoint test (optional):

```bash
POST /api/auth/forgot-password
{
  "email": "test@example.com"
}
```

## 3. Flow Forgot Password

### Step 1: Request Reset
```bash
POST /api/auth/forgot-password
{
  "email": "user@example.com"
}
```

Response:
```json
{
  "status": "success",
  "message": "Kode verifikasi telah dikirim ke email Anda"
}
```

### Step 2: Verify Code
```bash
POST /api/auth/verify-code
{
  "email": "user@example.com",
  "code": "123456"
}
```

Response:
```json
{
  "status": "success",
  "message": "Kode verifikasi valid"
}
```

### Step 3: Reset Password
```bash
POST /api/auth/reset-password
{
  "email": "user@example.com",
  "code": "123456",
  "newPassword": "newpassword123"
}
```

Response:
```json
{
  "status": "success",
  "message": "Password berhasil direset"
}
```

## 4. Catatan

- Kode verifikasi valid selama 15 menit
- Kode adalah 6 digit angka random
- Email harus sudah terdaftar di sistem
- Setelah password direset, kode otomatis dihapus

## 5. Alternatif Email Provider

Jika tidak ingin pakai Gmail, bisa gunakan:

### Mailtrap (Development)
```env
EMAIL_HOST=smtp.mailtrap.io
EMAIL_PORT=2525
EMAIL_USER=your_mailtrap_user
EMAIL_PASSWORD=your_mailtrap_password
```

### SendGrid
```env
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USER=apikey
EMAIL_PASSWORD=your_sendgrid_api_key
```

### Mailgun
```env
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USER=your_mailgun_username
EMAIL_PASSWORD=your_mailgun_password
```
