const express = require('express');
const router = express.Router();
const predictionController = require('../controllers/prediction.controller');
const verifyToken = require('../middleware/auth.middleware');

// Predict with custom data (protected)
router.post('/predict', verifyToken, predictionController.predictCrop);

// Predict using latest sensor data from MQTT (protected)
router.get('/predict/latest', verifyToken, predictionController.predictFromLatestSensor);
router.post('/predict/latest', verifyToken, predictionController.predictFromLatestSensor);

module.exports = router;
