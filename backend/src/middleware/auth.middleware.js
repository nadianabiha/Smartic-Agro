const jwt = require('jsonwebtoken');
const authConfig = require('../config/auth.config');

const verifyToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1] || req.headers['x-access-token'];

    if (!token) {
        return res.status(403).json({
            status: 'error',
            message: 'Token tidak ditemukan'
        });
    }

    try {
        const decoded = jwt.verify(token, authConfig.secret);
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({
            status: 'error',
            message: 'Token tidak valid atau sudah kadaluarsa'
        });
    }
};

module.exports = verifyToken;
