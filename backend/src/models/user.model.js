const pool = require('../config/database.config');

class UserModel {
    async create(username, email, hashedPassword) {
        const query = `
            INSERT INTO users (username, email, password, created_at, updated_at)
            VALUES ($1, $2, $3, NOW(), NOW())
            RETURNING id, username, email, created_at
        `;
        const values = [username, email, hashedPassword];
        const result = await pool.query(query, values);
        return result.rows[0];
    }

    async findByEmail(email) {
        const query = 'SELECT * FROM users WHERE email = $1';
        const result = await pool.query(query, [email]);
        return result.rows[0];
    }

    async findByUsername(username) {
        const query = 'SELECT * FROM users WHERE username = $1';
        const result = await pool.query(query, [username]);
        return result.rows[0];
    }

    async findById(id) {
        const query = 'SELECT id, username, email, created_at, updated_at FROM users WHERE id = $1';
        const result = await pool.query(query, [id]);
        return result.rows[0];
    }

    async updateLastLogin(userId) {
        const query = 'UPDATE users SET last_login = NOW(), updated_at = NOW() WHERE id = $1';
        await pool.query(query, [userId]);
    }

    async saveResetCode(userId, code, expiresAt) {
        const query = 'UPDATE users SET reset_code = $1, reset_code_expires = $2, updated_at = NOW() WHERE id = $3';
        await pool.query(query, [code, expiresAt, userId]);
    }

    async findByEmailAndResetCode(email, code) {
        const query = 'SELECT * FROM users WHERE email = $1 AND reset_code = $2';
        const result = await pool.query(query, [email, code]);
        return result.rows[0];
    }

    async updatePassword(userId, hashedPassword) {
        const query = 'UPDATE users SET password = $1, reset_code = NULL, reset_code_expires = NULL, updated_at = NOW() WHERE id = $2';
        await pool.query(query, [hashedPassword, userId]);
    }
}

module.exports = new UserModel();
