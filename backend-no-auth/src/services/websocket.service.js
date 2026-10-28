const { Server } = require('socket.io');

class WebSocketService {
    constructor() {
        this.io = null;
        this.connectedClients = new Set();
    }

    getTimestamp() {
        return new Date().toISOString().replace('T', ' ').substring(0, 19);
    }

    initialize(httpServer) {
        this.io = new Server(httpServer, {
            cors: {
                origin: "*", // In production, specify your mobile app domain
                methods: ["GET", "POST"],
                credentials: true
            },
            pingTimeout: 60000,
            pingInterval: 25000
        });

        this.setupEventHandlers();
        console.log(`${this.getTimestamp()} [INFO] WebSocket: Server initialized`);
    }

    setupEventHandlers() {
        this.io.on('connection', (socket) => {
            this.connectedClients.add(socket.id);
            console.log(`${this.getTimestamp()} [INFO] WebSocket: Client connected [${socket.id}] - Total: ${this.connectedClients.size}`);

            socket.on('disconnect', (reason) => {
                this.connectedClients.delete(socket.id);
                console.log(`${this.getTimestamp()} [INFO] WebSocket: Client disconnected [${socket.id}] - Reason: ${reason} - Total: ${this.connectedClients.size}`);
            });

            socket.on('error', (error) => {
                console.log(`${this.getTimestamp()} [ERROR] WebSocket: Error on client [${socket.id}] - ${error.message}`);
            });

            // Handle ping from client
            socket.on('ping', () => {
                socket.emit('pong');
            });

            // Send welcome message with current connection count
            socket.emit('welcome', {
                message: 'Connected to sensor data stream',
                clientId: socket.id,
                connectedClients: this.connectedClients.size
            });
        });
    }

    /**
     * Broadcast sensor data to all connected clients
     * @param {Object} data - Sensor data object
     */
    broadcastSensorData(data) {
        if (!this.io) {
            console.log(`${this.getTimestamp()} [WARNING] WebSocket: Not initialized, cannot broadcast`);
            return;
        }

        if (this.connectedClients.size === 0) {
            // No clients connected, skip broadcast
            return;
        }

        // Emit to all connected clients
        this.io.emit('sensor-data', {
            timestamp: Date.now(),
            data: data
        });

        console.log(`${this.getTimestamp()} [DEBUG] WebSocket: Broadcasted sensor data to ${this.connectedClients.size} clients`);
    }

    /**
     * Get number of connected clients
     */
    getConnectedClientsCount() {
        return this.connectedClients.size;
    }

    /**
     * Disconnect all clients and close server
     */
    close() {
        if (this.io) {
            this.io.close();
            console.log(`${this.getTimestamp()} [INFO] WebSocket: Server closed`);
        }
    }
}

module.exports = new WebSocketService();
