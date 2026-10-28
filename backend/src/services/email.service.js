const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = nodemailer.createTransport({
            host: process.env.EMAIL_HOST || 'smtp.gmail.com',
            port: parseInt(process.env.EMAIL_PORT) || 587,
            secure: false, // true for 465, false for other ports
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASSWORD
            }
        });
    }

    async sendResetPasswordEmail(email, code, username) {
        try {
            // Log ke console untuk testing
            console.log('\n==========================================');
            console.log('📧 EMAIL RESET PASSWORD');
            console.log('==========================================');
            console.log(`To: ${email}`);
            console.log(`Username: ${username}`);
            console.log(`Reset Code: ${code}`);
            console.log(`Valid for: 15 minutes`);
            console.log('==========================================\n');

            const mailOptions = {
                from: process.env.EMAIL_FROM || `"Sensor App" <${process.env.EMAIL_USER}>`,
                to: email,
                subject: 'Reset Password - Kode Verifikasi',
                html: `
                    <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: 0 auto;">
                        <h2 style="color: #0D7377;">Reset Password</h2>
                        <p>Hi <strong>${username}</strong>,</p>
                        <p>Anda menerima email ini karena ada permintaan reset password untuk akun Anda.</p>
                        
                        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0;">
                            <p style="margin: 0; font-size: 14px;">Kode Verifikasi Anda:</p>
                            <h1 style="margin: 10px 0; color: #0D7377; font-size: 32px; letter-spacing: 5px;">${code}</h1>
                            <p style="margin: 0; font-size: 12px; color: #666;">Kode ini berlaku selama 15 menit</p>
                        </div>
                        
                        <p>Jika Anda tidak meminta reset password, abaikan email ini.</p>
                        
                        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                        <p style="font-size: 12px; color: #999;">
                            Email otomatis, jangan balas email ini.
                        </p>
                    </div>
                `
            };

            try {
                const info = await this.transporter.sendMail(mailOptions);
                console.log('✅ Email sent successfully:', info.messageId);
            } catch (emailError) {
                console.log('⚠️  Email sending failed:', emailError.message);
                console.log('💡 Kode tetap tersimpan di database untuk testing');
            }
            
            return true;
        } catch (error) {
            console.error('Email error:', error);
            throw new Error('Gagal mengirim email');
        }
    }

    async sendWelcomeEmail(email, username) {
        try {
            const mailOptions = {
                from: process.env.EMAIL_FROM || `"Sensor App" <${process.env.EMAIL_USER}>`,
                to: email,
                subject: 'Selamat Datang di Sensor App',
                html: `
                    <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: 0 auto;">
                        <h2 style="color: #0D7377;">Selamat Datang!</h2>
                        <p>Hi <strong>${username}</strong>,</p>
                        <p>Terima kasih telah mendaftar di Sensor App. Akun Anda telah berhasil dibuat.</p>
                        
                        <p>Anda sekarang dapat:</p>
                        <ul>
                            <li>Memantau data sensor secara realtime</li>
                            <li>Mendapatkan prediksi tanaman</li>
                            <li>Melihat riwayat data sensor</li>
                        </ul>
                        
                        <p>Jika ada pertanyaan, jangan ragu untuk menghubungi kami.</p>
                        
                        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                        <p style="font-size: 12px; color: #999;">Email otomatis, jangan balas email ini.</p>
                    </div>
                `
            };

            await this.transporter.sendMail(mailOptions);
            return true;
        } catch (error) {
            console.error('Welcome email error:', error);
            // Don't throw error, just log it
            return false;
        }
    }
}

module.exports = new EmailService();
