/**
 * Migration: Create users table
 * Created: 2026-01-13
 */

module.exports = {
    async up(client) {
        console.log('  📋 Creating users table...');
        
        await client.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_login TIMESTAMP
            );
        `);

        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        `);

        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
        `);

        console.log('  ✅ Users table created');
    },

    async down(client) {
        console.log('  📋 Dropping users table...');
        
        await client.query(`DROP TABLE IF EXISTS users CASCADE;`);
        
        console.log('  ✅ Users table dropped');
    }
};
