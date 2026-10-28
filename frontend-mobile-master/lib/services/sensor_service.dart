import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction_models.dart';
import '../constants/app_constants.dart';

class SensorService {
  Future<SensorData?> fetchLatestSensorData() async {
    try {
      final response = await http
          .get(Uri.parse(AppConstants.sensorApiUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (jsonResponse['status'] != 'success' ||
          !jsonResponse.containsKey('data')) {
        throw Exception('Invalid API response');
      }

      final data = jsonResponse['data'] as Map<String, dynamic>;
      return SensorData.fromJson(data);
    } catch (e) {
      print('Error fetching sensor data: $e');
      return null;
    }
  }
}

class PredictionService {
  Future<PredictionResult?> predict(Map<String, double> sensorData) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.predictUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(sensorData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Prediction failed: HTTP ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      // Backend mengembalikan data langsung, bukan dalam wrapper 'data'
      if (jsonResponse['status'] == 'success') {
        return PredictionResult.fromJson(jsonResponse);
      } else {
        throw Exception('Prediction failed: ${jsonResponse['message']}');
      }
    } catch (e) {
      print('Error predicting: $e');
      return null;
    }
  }
}
