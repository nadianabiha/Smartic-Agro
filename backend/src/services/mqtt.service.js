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
        
        // Log raw payload untuk debugging
        console.log(`${this.getTimestamp()} [DEBUG] RAW MQTT Payload: ${payloadStr}`);
        
        try {
            const data = JSON.parse(payloadStr);
            
            // Support 2 format:
            // Format 1: {soil: {...}, gps: {...}}
            // Format 2: {N: x, P: y, ...} (flat structure)
            
            let soilData = data.soil || data; // Gunakan data langsung jika tidak ada key 'soil'
            
            // Parse GPS
            if (data.gps) {
                const gpsData = data.gps;
                this.latestSensorData.lat = parseFloat(gpsData.lat || gpsData.latitude) || 0.0;
                this.latestSensorData.lon = parseFloat(gpsData.lon || gpsData.longitude) || 0.0;
                this.latestSensorData.alt = parseFloat(gpsData.alt || gpsData.altitude) || 0.0;
                this.latestSensorData.sat = parseInt(gpsData.sat || gpsData.satellites) || 0;
                console.log(`${this.getTimestamp()} [INFO] MQTT: GPS updated - Lat: ${this.latestSensorData.lat}, Lon: ${this.latestSensorData.lon}`);
            } else if (data.latitude !== undefined || data.lat !== undefined) {
                // GPS data in root level
                this.latestSensorData.lat = parseFloat(data.lat || data.latitude) || 0.0;
                this.latestSensorData.lon = parseFloat(data.lon || data.longitude) || 0.0;
                this.latestSensorData.alt = parseFloat(data.alt || data.altitude) || 0.0;
                this.latestSensorData.sat = parseInt(data.sat || data.satellites) || 0;
            }
            
            // Parse soil data - support both lowercase and uppercase
            if (soilData) {
                // Temperature
                this.latestSensorData.temperature = parseFloat(soilData.temperature || soilData.Temperature || soilData.temp) || 0.0;
                
                // Humidity
                this.latestSensorData.humidity = parseFloat(soilData.humidity || soilData.Humidity) || 0.0;
                
                // N, P, K (NPK nutrients)
                this.latestSensorData.N = parseFloat(soilData.n || soilData.N) || 0.0;
                this.latestSensorData.P = parseFloat(soilData.p || soilData.P) || 0.0;
                this.latestSensorData.K = parseFloat(soilData.k || soilData.K) || 0.0;
                
                // pH
                this.latestSensorData.pH = parseFloat(soilData.ph || soilData.pH || soilData.Ph) || 0.0;
                
                // EC (Electrical Conductivity)
                this.latestSensorData.ec = parseFloat(soilData.ec || soilData.EC || soilData.Ec) || 0.0;
                
                console.log(`${this.getTimestamp()} [DEBUG] Soil parsed - N:${this.latestSensorData.N}, P:${this.latestSensorData.P}, K:${this.latestSensorData.K}, pH:${this.latestSensorData.pH}, EC:${this.latestSensorData.ec}`);
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

    publishRecommendation(recommendations) {
        if (!this.client || !this.client.connected) {
            console.log(`${this.getTimestamp()} [WARNING] MQTT: Tidak bisa publish rekomendasi, client belum terkoneksi`);
            return false;
        }

        const topic = mqttConfig.recommendationTopic || "smartfarming/recommendation";
        const payload = {
            recommendations: recommendations,
            timestamp: Date.now()
        };

        this.client.publish(
            topic,
            JSON.stringify(payload),
            { qos: 1, retain: true },
            (err) => {
                if (err) {
                    console.log(`${this.getTimestamp()} [ERROR] MQTT: Gagal publish rekomendasi - ${err.message}`);
                } else {
                    console.log(`${this.getTimestamp()} [INFO] MQTT: Rekomendasi dipublish ke ${topic}`);
                    console.log(`${this.getTimestamp()} [DEBUG] Payload: ${JSON.stringify(payload)}`);
                }
            }
        );

        return true;
    }

    disconnect() {
        if (this.client) {
            this.client.end();
        }
    }
}

module.exports = new MqttService();
