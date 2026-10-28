const axios = require('axios');
const path = require('path');
const mqttService = require('../services/mqtt.service');

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000';

class PredictionController {
    async predictCrop(req, res) {
        try {
            const { N, P, K, temperature, humidity, pH, altitude } = req.body;

            // Validasi input
            const requiredFields = ['N', 'P', 'K', 'temperature', 'humidity', 'pH'];
            const missingFields = requiredFields.filter(field => req.body[field] === undefined);

            if (missingFields.length > 0) {
                return res.status(400).json({
                    status: 'error',
                    message: `Missing required fields: ${missingFields.join(', ')}`
                });
            }

            // Prepare input data
            const inputData = {
                N: parseFloat(N),
                P: parseFloat(P),
                K: parseFloat(K),
                temperature: parseFloat(temperature),
                humidity: parseFloat(humidity),
                pH: parseFloat(pH),
                altitude: parseFloat(altitude || 0)
            };

            // Call FastAPI ML Service
            try {
                const response = await axios.post(`${ML_SERVICE_URL}/predict`, inputData);
                res.json(response.data);
            } catch (apiError) {
                console.error('ML API error:', apiError.message);
                return res.status(500).json({
                    status: 'error',
                    message: 'Prediction failed. ML service is unreachable or returned an error.'
                });
            }

        } catch (error) {
            console.error('Prediction error:', error);
            res.status(500).json({
                status: 'error',
                message: error.message
            });
        }
    }

    async predictFromLatestSensor(req, res) {
        try {
            // Ambil data sensor terbaru dari MQTT
            const latestData = mqttService.getLatestData();

            // Check jika data sensor valid
            if (latestData.status_mqtt !== 'CONNECTED') {
                return res.status(503).json({
                    status: 'error',
                    message: 'MQTT not connected. Cannot get sensor data.'
                });
            }

            // Check jika ada data sensor (bukan semua 0)
            const hasValidData = latestData.N > 0 || latestData.P > 0 || latestData.K > 0;
            if (!hasValidData) {
                return res.status(400).json({
                    status: 'error',
                    message: 'No valid sensor data available. All values are zero.'
                });
            }

            // Prepare input data with altitude
            const inputData = {
                N: parseFloat(latestData.N),
                P: parseFloat(latestData.P),
                K: parseFloat(latestData.K),
                temperature: parseFloat(latestData.temperature),
                humidity: parseFloat(latestData.humidity),
                pH: parseFloat(latestData.pH),
                altitude: parseFloat(req.query.altitude || req.body.altitude || 0) 
            };

            try {
                const response = await axios.post(`${ML_SERVICE_URL}/predict`, inputData);
                const parsedResult = response.data;
                
                // Prepare response for mobile
                const finalResponse = {
                    ...parsedResult,
                    sensor_data: {
                        N: latestData.N,
                        P: latestData.P,
                        K: latestData.K,
                        temperature: latestData.temperature,
                        humidity: latestData.humidity,
                        pH: latestData.pH,
                        ec: latestData.ec,
                        timestamp: latestData.timestamp
                    }
                };
                
                // Send response to mobile
                res.json(finalResponse);
                
                // Publish recommendation to MQTT for ESP32/LCD
                if (parsedResult.data && parsedResult.data.top_crops) {
                    // Ambil top 3 tanaman dengan format crop dan probability
                    const top3 = parsedResult.data.top_crops
                        .slice(0, 3)
                        .map(item => ({
                            crop: item.crop,
                            probability: item.probability
                        }));
                    
                    mqttService.publishRecommendation(top3);
                    console.log('Rekomendasi dipublish ke MQTT:', top3);
                }
            } catch (apiError) {
                console.error('ML API error:', apiError.message);
                return res.status(500).json({
                    status: 'error',
                    message: 'Prediction failed. ML service is unreachable or returned an error.'
                });
            }

        } catch (error) {
            console.error('Prediction error:', error);
            res.status(500).json({
                status: 'error',
                message: error.message || 'Terjadi kesalahan saat prediksi'
            });
        }
    }
}

module.exports = new PredictionController();
