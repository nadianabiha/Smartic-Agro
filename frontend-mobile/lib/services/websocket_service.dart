import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logging/logging.dart';

typedef SensorDataCallback = void Function(Map<String, dynamic> data);

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final _logger = Logger('WebSocketService');
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _serverUrl;

  final List<SensorDataCallback> _sensorDataListeners = [];

  bool get isConnected => _isConnected;

  /// Initialize and connect to WebSocket server
  void connect(String serverUrl) {
    if (_socket != null && _isConnected) {
      _logger.info('Already connected to WebSocket');
      return;
    }

    _serverUrl = serverUrl;
    _logger.info('Connecting to WebSocket: $serverUrl');

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .setTimeout(20000)
          .build(),
    );

    _setupEventHandlers();
    _socket!.connect();
  }

  void _setupEventHandlers() {
    _socket!.onConnect((_) {
      _isConnected = true;
      _logger.info('✅ WebSocket Connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _logger.warning('⚠️ WebSocket Disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      _logger.severe('❌ WebSocket Connection Error: $error');
    });

    _socket!.onError((error) {
      _logger.severe('❌ WebSocket Error: $error');
    });

    _socket!.on('welcome', (data) {
      _logger.info('Welcome message: $data');
    });

    // Listen for sensor data broadcasts
    _socket!.on('sensor-data', (data) {
      _logger.info('📡 Received sensor data via WebSocket');

      if (data is Map) {
        final sensorData = data['data'] as Map<String, dynamic>?;
        if (sensorData != null) {
          // Notify all listeners
          for (var listener in _sensorDataListeners) {
            listener(sensorData);
          }
        }
      }
    });

    _socket!.on('pong', (_) {
      _logger.fine('Pong received');
    });
  }

  /// Add listener for real-time sensor data updates
  void addSensorDataListener(SensorDataCallback callback) {
    if (!_sensorDataListeners.contains(callback)) {
      _sensorDataListeners.add(callback);
      _logger.info(
          'Sensor data listener added. Total: ${_sensorDataListeners.length}');
    }
  }

  /// Remove listener
  void removeSensorDataListener(SensorDataCallback callback) {
    _sensorDataListeners.remove(callback);
    _logger.info(
        'Sensor data listener removed. Total: ${_sensorDataListeners.length}');
  }

  /// Send ping to server
  void ping() {
    if (_isConnected && _socket != null) {
      _socket!.emit('ping');
    }
  }

  /// Reconnect to server
  void reconnect() {
    if (_socket != null) {
      _logger.info('Attempting to reconnect...');
      _socket!.connect();
    } else if (_serverUrl != null) {
      connect(_serverUrl!);
    }
  }

  /// Disconnect from server
  void disconnect() {
    if (_socket != null) {
      _logger.info('Disconnecting from WebSocket');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _sensorDataListeners.clear();
    }
  }
}
