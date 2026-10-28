require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    database: process.env.DB_NAME || 'sensor_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || '',
});

const MIGRATIONS_DIR = path.join(__dirname, 'migrations');

/**
 * Create migrations tracking table
 */
async function createMigrationsTable(client) {
    await client.query(`
        CREATE TABLE IF NOT EXISTS migrations (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) UNIQUE NOT NULL,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `);
}

/**
 * Get list of executed migrations
 */
async function getExecutedMigrations(client) {
    const result = await client.query(
        'SELECT name FROM migrations ORDER BY name'
    );
    return result.rows.map(row => row.name);
}

/**
 * Get list of pending migrations
 */
async function getPendingMigrations(executedMigrations) {
    const files = fs.readdirSync(MIGRATIONS_DIR)
        .filter(file => file.endsWith('.js'))
        .sort();

    return files.filter(file => !executedMigrations.includes(file));
}

/**
 * Run migrations
 */
async function migrate(action = 'up') {
    const client = await pool.connect();
    
    try {
        console.log('🚀 Starting database migration...\n');

        // Create migrations table if not exists
        await createMigrationsTable(client);

        if (action === 'up') {
            // Run pending migrations
            const executedMigrations = await getExecutedMigrations(client);
            const pendingMigrations = await getPendingMigrations(executedMigrations);

            if (pendingMigrations.length === 0) {
                console.log('✅ No pending migrations. Database is up to date!\n');
                return;
            }

            console.log(`📋 Found ${pendingMigrations.length} pending migration(s):\n`);
            
            for (const migrationFile of pendingMigrations) {
                console.log(`⏳ Running: ${migrationFile}`);
                
                await client.query('BEGIN');
                
                try {
                    const migrationPath = path.join(MIGRATIONS_DIR, migrationFile);
                    const migration = require(migrationPath);
                    
                    await migration.up(client);
                    
                    await client.query(
                        'INSERT INTO migrations (name) VALUES ($1)',
                        [migrationFile]
                    );
                    
                    await client.query('COMMIT');
                    console.log(`✅ Completed: ${migrationFile}\n`);
                } catch (error) {
                    await client.query('ROLLBACK');
                    throw error;
                }
            }

            console.log('🎉 All migrations completed successfully!\n');
        } else if (action === 'down') {
            // Rollback last migration
            const executedMigrations = await getExecutedMigrations(client);
            
            if (executedMigrations.length === 0) {
                console.log('⚠️  No migrations to rollback.\n');
                return;
            }

            const lastMigration = executedMigrations[executedMigrations.length - 1];
            console.log(`⏳ Rolling back: ${lastMigration}`);
            
            await client.query('BEGIN');
            
            try {
                const migrationPath = path.join(MIGRATIONS_DIR, lastMigration);
                const migration = require(migrationPath);
                
                await migration.down(client);
                
                await client.query(
                    'DELETE FROM migrations WHERE name = $1',
                    [lastMigration]
                );
                
                await client.query('COMMIT');
                console.log(`✅ Rolled back: ${lastMigration}\n`);
            } catch (error) {
                await client.query('ROLLBACK');
                throw error;
            }
        } else if (action === 'status') {
            // Show migration status
            const executedMigrations = await getExecutedMigrations(client);
            const allMigrations = fs.readdirSync(MIGRATIONS_DIR)
                .filter(file => file.endsWith('.js'))
                .sort();

            console.log('📊 Migration Status:\n');
            
            allMigrations.forEach(migration => {
                const status = executedMigrations.includes(migration) ? '✅' : '⏳';
                console.log(`${status} ${migration}`);
            });
            
            console.log(`\nExecuted: ${executedMigrations.length}/${allMigrations.length}\n`);
        }

    } catch (error) {
        console.error('\n❌ Migration failed:', error.message);
        console.error('Details:', error);
        process.exit(1);
    } finally {
        client.release();
        await pool.end();
    }
}

// Parse command line arguments
const action = process.argv[2] || 'up';

if (!['up', 'down', 'status'].includes(action)) {
    console.error('Usage: node migrator.js [up|down|status]');
    console.error('  up     - Run pending migrations (default)');
    console.error('  down   - Rollback last migration');
    console.error('  status - Show migration status');
    process.exit(1);
}

migrate(action);
