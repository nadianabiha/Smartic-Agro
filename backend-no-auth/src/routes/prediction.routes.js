const express = require('express');
const router = express.Router();
const predictionController = require('../controllers/prediction.controller');

// Predict with custom data (no auth required)
router.post('/predict', predictionController.predictCrop);

// Predict using latest sensor data from MQTT (no auth required)
router.get('/predict/latest', predictionController.predictFromLatestSensor);

module.exports = router;
