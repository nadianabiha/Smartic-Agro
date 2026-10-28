require('dotenv').config();

module.exports = {
    host: process.env.SERVER_HOST || '0.0.0.0',
    port: parseInt(process.env.SERVER_PORT) || 5010,
    env: process.env.NODE_ENV || 'development'
};
