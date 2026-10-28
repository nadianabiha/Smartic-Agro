const { PythonShell } = require('python-shell');
const path = require('path');
const mqttService = require('../services/mqtt.service');

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

            // Python shell options
            const options = {
                mode: 'text',
                pythonPath: 'python',
                scriptPath: path.join(__dirname, '../../ml-service'),
                args: []
            };

            // Run Python script
            const pyshell = new PythonShell('predict.py', options);
            
            // Send input data
            pyshell.send(JSON.stringify(inputData));

            let result = '';

            pyshell.on('message', (message) => {
                result += message;
            });

            pyshell.end((err) => {
                if (err) {
                    console.error('Python error:', err);
                    return res.status(500).json({
                        status: 'error',
                        message: 'Prediction failed. Please check if Python and required packages are installed.'
                    });
                }

                try {
                    const parsedResult = JSON.parse(result);
                    res.json(parsedResult);
                } catch (parseError) {
                    res.status(500).json({
                        status: 'error',
                        message: 'Failed to parse prediction result'
                    });
                }
            });

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
                altitude: parseFloat(req.query.altitude || 0) // altitude from query or default 0
            };

            // Python shell options
            const options = {
                mode: 'text',
                pythonPath: 'python',
                scriptPath: path.join(__dirname, '../../ml-service'),
                args: []
            };

            // Run Python script
            const pyshell = new PythonShell('predict.py', options);
            
            pyshell.send(JSON.stringify(inputData));

            let result = '';

            pyshell.on('message', (message) => {
                result += message;
            });

            pyshell.end((err) => {
                if (err) {
                    console.error('Python error:', err);
                    return res.status(500).json({
                        status: 'error',
                        message: 'Prediction failed'
                    });
                }

                try {
                    const parsedResult = JSON.parse(result);
                    res.json({
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
                    });
                } catch (parseError) {
                    res.status(500).json({
                        status: 'error',
                        message: 'Failed to parse prediction result'
                    });
                }
            });

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
