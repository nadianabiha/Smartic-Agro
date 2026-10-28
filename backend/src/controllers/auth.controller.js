const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const userModel = require('../models/user.model');
const authConfig = require('../config/auth.config');
const emailService = require('../services/email.service');

class AuthController {
    async register(req, res) {
        try {
            const { username, email, password } = req.body;

            // Validasi input
            if (!username || !email || !password) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Username, email, dan password harus diisi'
                });
            }

            // Validasi email format
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Format email tidak valid'
                });
            }

            // Validasi password minimal 6 karakter
            if (password.length < 6) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Password minimal 6 karakter'
                });
            }

            // Cek apakah email sudah terdaftar
            const existingEmail = await userModel.findByEmail(email);
            if (existingEmail) {
                return res.status(409).json({
                    status: 'error',
                    message: 'Email sudah terdaftar'
                });
            }

            // Cek apakah username sudah terdaftar
            const existingUsername = await userModel.findByUsername(username);
            if (existingUsername) {
                return res.status(409).json({
                    status: 'error',
                    message: 'Username sudah digunakan'
                });
            }

            // Hash password
            const hashedPassword = await bcrypt.hash(password, authConfig.saltRounds);

            // Simpan user ke database
            const newUser = await userModel.create(username, email, hashedPassword);

            // Generate JWT token
            const token = jwt.sign(
                { id: newUser.id, username: newUser.username, email: newUser.email },
                authConfig.secret,
                { expiresIn: authConfig.expiresIn }
            );

            res.status(201).json({
                status: 'success',
                message: 'Registrasi berhasil',
                data: {
                    user: {
                        id: newUser.id,
                        username: newUser.username,
                        email: newUser.email,
                        created_at: newUser.created_at
                    },
                    token: token
                }
            });
        } catch (error) {
            console.error('Register error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Terjadi kesalahan saat registrasi'
            });
        }
    }

    async login(req, res) {
        try {
            const { email, password } = req.body;

            // Validasi input
            if (!email || !password) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Email dan password harus diisi'
                });
            }

            // Cari user berdasarkan email
            const user = await userModel.findByEmail(email);
            if (!user) {
                return res.status(401).json({
                    status: 'error',
                    message: 'Email atau password salah'
                });
            }

            // Verifikasi password
            const isPasswordValid = await bcrypt.compare(password, user.password);
            if (!isPasswordValid) {
                return res.status(401).json({
                    status: 'error',
                    message: 'Email atau password salah'
                });
            }

            // Update last login
            await userModel.updateLastLogin(user.id);

            // Generate JWT token
            const token = jwt.sign(
                { id: user.id, username: user.username, email: user.email },
                authConfig.secret,
                { expiresIn: authConfig.expiresIn }
            );

            res.json({
                status: 'success',
                message: 'Login berhasil',
                data: {
                    user: {
                        id: user.id,
                        username: user.username,
                        email: user.email
                    },
                    token: token
                }
            });
        } catch (error) {
            console.error('Login error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Terjadi kesalahan saat login'
            });
        }
    }

    async getProfile(req, res) {
        try {
            const user = await userModel.findById(req.user.id);
            
            if (!user) {
                return res.status(404).json({
                    status: 'error',
                    message: 'User tidak ditemukan'
                });
            }

            res.json({
                status: 'success',
                data: {
                    user: user
                }
            });
        } catch (error) {
            console.error('Get profile error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Terjadi kesalahan saat mengambil profil'
            });
        }
    }

    async requestPasswordReset(req, res) {
        try {
            const { email } = req.body;

            if (!email) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Email harus diisi'
                });
            }

            // Cari user
            const user = await userModel.findByEmail(email);
            if (!user) {
                // Return success untuk security (jangan beritahu email tidak terdaftar)
                return res.json({
                    status: 'success',
                    message: 'Jika email terdaftar, kode verifikasi akan dikirim'
                });
            }

            // Generate kode 6 digit
            const resetCode = crypto.randomInt(100000, 999999).toString();
            const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 menit

            // Simpan ke database
            await userModel.saveResetCode(user.id, resetCode, expiresAt);

            // Kirim email
            await emailService.sendResetPasswordEmail(email, resetCode, user.username);

            res.json({
                status: 'success',
                message: 'Kode verifikasi telah dikirim ke email Anda'
            });

        } catch (error) {
            console.error('Request reset error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Gagal mengirim kode verifikasi'
            });
        }
    }

    async verifyResetCode(req, res) {
        try {
            const { email, code } = req.body;

            if (!email || !code) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Email dan kode harus diisi'
                });
            }

            const user = await userModel.findByEmailAndResetCode(email, code);

            if (!user) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Kode verifikasi tidak valid'
                });
            }

            // Cek expired
            if (new Date() > new Date(user.reset_code_expires)) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Kode verifikasi sudah kadaluarsa'
                });
            }

            res.json({
                status: 'success',
                message: 'Kode verifikasi valid'
            });

        } catch (error) {
            console.error('Verify code error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Terjadi kesalahan saat verifikasi'
            });
        }
    }

    async resetPassword(req, res) {
        try {
            const { email, code, newPassword } = req.body;

            if (!email || !code || !newPassword) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Email, kode, dan password baru harus diisi'
                });
            }

            if (newPassword.length < 6) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Password minimal 6 karakter'
                });
            }

            const user = await userModel.findByEmailAndResetCode(email, code);

            if (!user) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Kode verifikasi tidak valid'
                });
            }

            // Cek expired
            if (new Date() > new Date(user.reset_code_expires)) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Kode verifikasi sudah kadaluarsa'
                });
            }

            // Hash password baru
            const hashedPassword = await bcrypt.hash(newPassword, authConfig.saltRounds);

            // Update password dan hapus reset code
            await userModel.updatePassword(user.id, hashedPassword);

            res.json({
                status: 'success',
                message: 'Password berhasil direset'
            });

        } catch (error) {
            console.error('Reset password error:', error);
            res.status(500).json({
                status: 'error',
                message: 'Gagal mereset password'
            });
        }
    }
}

module.exports = new AuthController();
