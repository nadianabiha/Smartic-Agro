/**
 * Migration: Add reset password columns to users table
 * Created: 2026-01-13
 */

module.exports = {
    async up(client) {
        console.log('  📋 Adding reset password columns...');
        
        await client.query(`
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS reset_code VARCHAR(6),
            ADD COLUMN IF NOT EXISTS reset_code_expires TIMESTAMP;
        `);

        console.log('  ✅ Reset password columns added');
    },

    async down(client) {
        console.log('  📋 Removing reset password columns...');
        
        await client.query(`
            ALTER TABLE users 
            DROP COLUMN IF EXISTS reset_code,
            DROP COLUMN IF EXISTS reset_code_expires;
        `);
        
        console.log('  ✅ Reset password columns removed');
    }
};
