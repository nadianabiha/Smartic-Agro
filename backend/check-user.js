require('dotenv').config();
const pool = require('./src/config/database.config');

async function checkUser() {
    try {
        console.log('🔍 Checking for user: test@example.com\n');
        
        const result = await pool.query(
            'SELECT id, username, email, created_at FROM users WHERE email = $1',
            ['test@example.com']
        );
        
        if (result.rows.length > 0) {
            console.log('✅ User found:');
            console.log(result.rows[0]);
        } else {
            console.log('❌ User NOT found in database');
            console.log('Creating user...\n');
            
            const bcrypt = require('bcrypt');
            const hashedPassword = await bcrypt.hash('password123', 10);
            
            const insertResult = await pool.query(
                'INSERT INTO users (username, email, password) VALUES ($1, $2, $3) RETURNING id, username, email, created_at',
                ['testuser', 'test@example.com', hashedPassword]
            );
            
            console.log('✅ User created:');
            console.log(insertResult.rows[0]);
        }
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

checkUser();
