const express = require('express');
const cors = require('cors');
const sensorRoutes = require('./routes/sensor.routes');
const predictionRoutes = require('./routes/prediction.routes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api', sensorRoutes);
app.use('/api', predictionRoutes);

// Alias routes untuk compatibility dengan frontend-mobile-master
// Route /predict tanpa prefix /api
app.post('/predict', require('./controllers/prediction.controller').predictCrop);
app.get('/predict/latest', require('./controllers/prediction.controller').predictFromLatestSensor);

// Health check endpoint (for Docker healthcheck)
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Sensor Backend API (No Authentication)',
        version: '1.0.0',
        note: 'Compatible dengan frontend-mobile-master',
        endpoints: {
            sensor: '/api/sensor/latest',
            health: '/health',
            prediction: {
                'POST /predict': 'Predict crop (compatible with frontend-mobile-master)',
                'POST /api/predict': 'Predict crop (alternative)',
                'GET /predict/latest': 'Predict from latest sensor data',
                'GET /api/predict/latest': 'Predict from latest sensor data (alternative)'
            },
            websocket: 'ws://localhost:5010 (real-time sensor data)'
        }
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        status: 'error',
        message: 'Endpoint not found'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        status: 'error',
        message: 'Internal server error'
    });
});

module.exports = app;
