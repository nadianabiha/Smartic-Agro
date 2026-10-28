const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const sensorRoutes = require('./routes/sensor.routes');
const authRoutes = require('./routes/auth.routes');
const predictionRoutes = require('./routes/prediction.routes');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate Limiting
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: { status: 'error', message: 'Terlalu banyak permintaan dari IP ini, silakan coba lagi setelah 15 menit.' }
});

// Apply rate limiter to all API routes
app.use('/api', apiLimiter);

// Routes
app.use('/api', sensorRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/prediction', predictionRoutes);

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
        message: 'Sensor Backend API',
        version: '1.0.0',
        endpoints: {
            sensor: '/api/sensor/latest',
            health: '/health',
            auth: {
                register: '/api/auth/register',
                login: '/api/auth/login',
                profile: '/api/auth/profile'
            },
            prediction: {
                predict: '/api/prediction/predict (POST, requires token)',
                predictLatest: '/api/prediction/predict/latest (GET, requires token)'
            }
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
