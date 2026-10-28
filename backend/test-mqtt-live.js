const mqtt = require('mqtt');

// Konfigurasi MQTT
const config = {
    broker: '103.151.63.79',
    port: 1882,
    topic: 'sensor/final'
};

console.log(`Connecting to MQTT Broker: ${config.broker}:${config.port}`);
console.log(`Subscribing to topic: ${config.topic}`);
console.log('-------------------------------------------\n');

// Connect ke MQTT broker
const client = mqtt.connect(`mqtt://${config.broker}:${config.port}`, {
    clientId: 'TestClient_' + Math.random().toString(16).substr(2, 8),
    clean: true,
    reconnectPeriod: 5000,
    connectTimeout: 30000
});

client.on('connect', () => {
    console.log('✓ Connected to MQTT broker');
    
    client.subscribe(config.topic, (err) => {
        if (err) {
            console.error('✗ Failed to subscribe:', err.message);
            process.exit(1);
        }
        console.log(`✓ Subscribed to topic: ${config.topic}`);
        console.log('\nWaiting for messages...\n');
    });
});

client.on('message', (topic, message) => {
    const timestamp = new Date().toISOString();
    const payload = message.toString();
    
    console.log('='.repeat(60));
    console.log(`Time: ${timestamp}`);
    console.log(`Topic: ${topic}`);
    console.log('Raw Payload:');
    console.log(payload);
    
    try {
        const data = JSON.parse(payload);
        console.log('\nParsed JSON:');
        console.log(JSON.stringify(data, null, 2));
        
        // Cek data yang ada
        console.log('\n--- Data Check ---');
        if (data.soil) {
            console.log('Soil data found:');
            console.log(`  N: ${data.soil.n}`);
            console.log(`  P: ${data.soil.p}`);
            console.log(`  K: ${data.soil.k}`);
            console.log(`  pH: ${data.soil.ph}`);
            console.log(`  EC: ${data.soil.ec}`);
            console.log(`  Temperature: ${data.soil.temperature}`);
            console.log(`  Humidity: ${data.soil.humidity}`);
        }
        if (data.gps) {
            console.log('GPS data found:');
            console.log(`  Lat: ${data.gps.lat}`);
            console.log(`  Lon: ${data.gps.lon}`);
            console.log(`  Alt: ${data.gps.alt}`);
            console.log(`  Sat: ${data.gps.sat}`);
        }
    } catch (e) {
        console.log('\n✗ Failed to parse JSON:', e.message);
    }
    
    console.log('='.repeat(60) + '\n');
});

client.on('error', (err) => {
    console.error('✗ MQTT Error:', err.message);
});

client.on('close', () => {
    console.log('✗ Connection closed');
});

client.on('reconnect', () => {
    console.log('⟳ Reconnecting...');
});

// Handle Ctrl+C
process.on('SIGINT', () => {
    console.log('\n\nClosing connection...');
    client.end();
    process.exit(0);
});
