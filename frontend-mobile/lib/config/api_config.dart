class ApiConfig {
  // Production Server
  static const String baseUrl = '${String.fromEnvironment(
    'SMARTIC_API_URL',
    defaultValue: 'http://localhost:5010',
  )}/api';

  // Development (Localhost)
  // static const String baseUrl = 'http://localhost:5010/api';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/auth/profile';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String verifyCode = '$baseUrl/auth/verify-code';
  static const String resetPassword = '$baseUrl/auth/reset-password';

  // Sensor endpoints
  static const String sensorLatest = '$baseUrl/sensor/latest';

  // Prediction endpoints
  static const String predict = '$baseUrl/predict';
  static const String predictLatest = '$baseUrl/predict/latest';
}
