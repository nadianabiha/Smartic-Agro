class ApiConfig {
  static const String baseUrl = 'http://localhost:5010/api';

  // Sensor endpoints
  static const String sensorLatest = '$baseUrl/sensor/latest';

  // Prediction endpoints
  static const String predict =
      'http://localhost:5010/predict'; // Tanpa /api prefix
  static const String predictLatest = '$baseUrl/predict/latest';
}
