const express = require('express');
const router = express.Router();
const sensorController = require('../controllers/sensor.controller');

// Endpoint untuk data sensor terbaru
router.get('/sensor/latest', sensorController.getLatestData);

// Health check endpoint
router.get('/health', sensorController.getHealth);

module.exports = router;
