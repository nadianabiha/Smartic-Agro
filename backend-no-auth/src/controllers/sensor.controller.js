const mqttService = require('../services/mqtt.service');

class SensorController {
    getLatestData(req, res) {
        try {
            const data = mqttService.getLatestData();
            res.json({
                status: 'success',
                data: data
            });
        } catch (error) {
            res.status(500).json({
                status: 'error',
                message: error.message
            });
        }
    }

    getHealth(req, res) {
        const data = mqttService.getLatestData();
        res.json({
            status: 'ok',
            mqtt_status: data.status_mqtt,
            uptime: process.uptime()
        });
    }
}

module.exports = new SensorController();
