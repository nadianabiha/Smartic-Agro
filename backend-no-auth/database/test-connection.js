const pool = require('../src/config/database.config');

async function testConnection() {
    console.log('🔍 Testing koneksi PostgreSQL...\n');
    console.log('Konfigurasi:');
    console.log(`  Host: ${process.env.DB_HOST || 'localhost'}`);
    console.log(`  Port: ${process.env.DB_PORT || '5432'}`);
    console.log(`  Database: ${process.env.DB_NAME || 'sensor_db'}`);
    console.log(`  User: ${process.env.DB_USER || 'postgres'}\n`);

    try {
        const client = await pool.connect();
        console.log('✅ Koneksi PostgreSQL berhasil!');
        
        // Get database version
        const result = await client.query('SELECT version()');
        console.log('\n📦 PostgreSQL Version:');
        console.log(`  ${result.rows[0].version.split(',')[0]}\n`);
        
        // List existing tables
        const tables = await client.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name
        `);
        
        if (tables.rows.length > 0) {
            console.log('📊 Tabel yang ada:');
            tables.rows.forEach(row => {
                console.log(`  - ${row.table_name}`);
            });
        } else {
            console.log('ℹ️  Belum ada tabel. Jalankan migrasi dengan: npm run migrate');
        }
        
        client.release();
        process.exit(0);
    } catch (error) {
        console.error('❌ Koneksi gagal:', error.message);
        
        if (error.code === 'ECONNREFUSED') {
            console.error('\n💡 Solusi:');
            console.error('   1. Pastikan PostgreSQL sudah terinstall');
            console.error('   2. Start PostgreSQL service');
            console.error('   3. Download dari: https://www.postgresql.org/download/');
        } else if (error.code === '3D000') {
            console.error('\n💡 Database tidak ada. Buat dulu dengan:');
            console.error('   CREATE DATABASE sensor_db;');
        } else if (error.code === '28P01') {
            console.error('\n💡 Password salah. Check DB_PASSWORD di .env');
        }
        
        process.exit(1);
    }
}

testConnection();
