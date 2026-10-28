/**
 * Migration: Create sensor_data table
 * Created: 2026-01-13
 */

module.exports = {
    async up(client) {
        console.log('  📋 Creating sensor_data table...');
        
        await client.query(`
            CREATE TABLE IF NOT EXISTS sensor_data (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                nitrogen DECIMAL(10, 2),
                phosphorus DECIMAL(10, 2),
                potassium DECIMAL(10, 2),
                temperature DECIMAL(10, 2),
                humidity DECIMAL(10, 2),
                ph DECIMAL(10, 2),
                ec DECIMAL(10, 2),
                latitude DECIMAL(10, 6),
                longitude DECIMAL(10, 6),
                altitude DECIMAL(10, 2),
                satellites INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);

        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_sensor_data_user_id ON sensor_data(user_id);
        `);

        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_sensor_data_created_at ON sensor_data(created_at);
        `);

        console.log('  ✅ Sensor_data table created');
    },

    async down(client) {
        console.log('  📋 Dropping sensor_data table...');
        
        await client.query(`DROP TABLE IF EXISTS sensor_data CASCADE;`);
        
        console.log('  ✅ Sensor_data table dropped');
    }
};
