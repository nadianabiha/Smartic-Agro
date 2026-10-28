const { PythonShell } = require('python-shell');
const path = require('path');

class PredictionService {
    constructor() {
        this.modelPath = path.join(__dirname, '../../predict_crop.py');
    }

    async predictCrop(sensorData) {
        return new Promise((resolve, reject) => {
            const options = {
                mode: 'json',
                pythonPath: 'python', // or 'python3' on Linux/Mac
                pythonOptions: ['-u'],
                scriptPath: path.dirname(this.modelPath),
                args: []
            };

            const pyshell = new PythonShell('predict_crop.py', options);

            // Send input data
            pyshell.send(JSON.stringify(sensorData));

            let result = null;

            pyshell.on('message', (message) => {
                result = message;
            });

            pyshell.end((err) => {
                if (err) {
                    reject(new Error(`Python error: ${err.message}`));
                } else if (result && result.status === 'error') {
                    reject(new Error(result.message));
                } else {
                    resolve(result);
                }
            });
        });
    }

    async predictFromSensorData(sensorData) {
        try {
            const input = {
                N: sensorData.N || 0,
                P: sensorData.P || 0,
                K: sensorData.K || 0,
                temperature: sensorData.temperature || 0,
                humidity: sensorData.humidity || 0,
                pH: sensorData.pH || 0,
                altitude: sensorData.altitude || 0
            };

            const prediction = await this.predictCrop(input);
            return prediction;
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new PredictionService();
