require('dotenv').config();

module.exports = {
    broker: process.env.MQTT_BROKER || '103.151.63.79',
    port: parseInt(process.env.MQTT_PORT) || 1882,
    topic: process.env.MQTT_TOPIC || 'sensor/final',
    clientId: 'NodeJsAppBackend',
    options: {
        clean: true,
        reconnectPeriod: 5000,
        connectTimeout: 30000
    }
};
