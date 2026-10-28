const mqtt = require('mqtt');
const mqttConfig = require('../config/mqtt.config');
const websocketService = require('./websocket.service');

class MqttService {
    constructor() {
        this.client = null;
        this.latestSensorData = {
            N: 0.0,
            P: 0.0,
            K: 0.0,
            temperature: 0.0,
            humidity: 0.0,
            pH: 0.0,
            ec: 0.0,
            lat: 0.0,
            lon: 0.0,
            alt: 0.0,
            sat: 0,
            timestamp: Date.now() / 1000,
            status_mqtt: 'INITIALIZING'
        };
    }

    getTimestamp() {
        return new Date().toISOString().replace('T', ' ').substring(0, 19);
    }

    connect() {
        const mqttUrl = `mqtt://${mqttConfig.broker}:${mqttConfig.port}`;
        
        console.log(`${this.getTimestamp()} [DEBUG] Mencoba koneksi ke ${mqttConfig.broker}:${mqttConfig.port}`);

        this.client = mqtt.connect(mqttUrl, {
            clientId: mqttConfig.clientId,
            ...mqttConfig.options
        });

        this.setupEventHandlers();
    }

    setupEventHandlers() {
        this.client.on('connect', () => {
            console.log(`${this.getTimestamp()} [INFO] MQTT: Terkoneksi ke broker. Mencoba subscribe ke ${mqttConfig.topic}...`);
            this.latestSensorData.status_mqtt = 'CONNECTED';
            
            this.client.subscribe(mqttConfig.topic, (err) => {
                if (err) {
                    console.log(`${this.getTimestamp()} [ERROR] MQTT: Gagal subscribe ke topic: ${err.message}`);
                } else {
                    console.log(`${this.getTimestamp()} [INFO] MQTT: Berhasil subscribe ke ${mqttConfig.topic}`);
                }
            });
        });

        this.client.on('close', () => {
            console.log(`${this.getTimestamp()} [WARNING] MQTT: TERPUTUS DARI BROKER`);
            this.latestSensorData.status_mqtt = 'DISCONNECTED';
        });

        this.client.on('error', (err) => {
            console.log(`${this.getTimestamp()} [ERROR] MQTT: ${err.message}`);
            this.latestSensorData.status_mqtt = `ERROR: ${err.message}`;
        });

        this.client.on('reconnect', () => {
            console.log(`${this.getTimestamp()} [INFO] MQTT: Mencoba reconnect...`);
            this.latestSensorData.status_mqtt = 'RECONNECTING';
        });

        this.client.on('message', (topic, message) => {
            this.handleMessage(message);
        });
    }

    handleMessage(message) {
        const payloadStr = message.toString();
        
        try {
            const data = JSON.parse(payloadStr);
            
            if (!data.soil) {
                console.log(`${this.getTimestamp()} [ERROR] MQTT: Kunci 'soil' tidak ditemukan dalam payload.`);
                return;
            }
            
            const soilData = data.soil;
            
            // Parse GPS
            if (data.gps) {
                const gpsData = data.gps;
                this.latestSensorData.lat = parseFloat(gpsData.lat) || 0.0;
                this.latestSensorData.lon = parseFloat(gpsData.lon) || 0.0;
                this.latestSensorData.alt = parseFloat(gpsData.alt) || 0.0;
                this.latestSensorData.sat = parseInt(gpsData.sat) || 0;
                console.log(`${this.getTimestamp()} [INFO] MQTT: GPS updated - Lat: ${this.latestSensorData.lat}, Lon: ${this.latestSensorData.lon}`);
            }
            
            // Parse soil data
            const targetKeys = ['N', 'P', 'K', 'temperature', 'humidity', 'pH', 'ec'];
            
            for (const key of targetKeys) {
                const sensorKeyPayload = key.toLowerCase();
                if (soilData[sensorKeyPayload] !== undefined) {
                    const value = soilData[sensorKeyPayload];
                    if (typeof value === 'number' || typeof value === 'string') {
                        this.latestSensorData[key] = parseFloat(value);
                    }
                }
            }
            
            this.latestSensorData.timestamp = Date.now() / 1000;
            console.log(`${this.getTimestamp()} [INFO] MQTT: Data sensor diperbarui. Temp: ${this.latestSensorData.temperature}°C, GPS: (${this.latestSensorData.lat}, ${this.latestSensorData.lon})`);
            
            // Broadcast data to WebSocket clients in real-time
            websocketService.broadcastSensorData(this.latestSensorData);
            
        } catch (err) {
            if (err instanceof SyntaxError) {
                console.log(`${this.getTimestamp()} [ERROR] MQTT: Gagal mendecode JSON dari payload: ${payloadStr}`);
            } else {
                console.log(`${this.getTimestamp()} [ERROR] MQTT: Error tak terduga dalam handleMessage: ${err.message}`);
            }
        }
    }

    getLatestData() {
        return { ...this.latestSensorData };
    }

    disconnect() {
        if (this.client) {
            this.client.end();
        }
    }
}

module.exports = new MqttService();
