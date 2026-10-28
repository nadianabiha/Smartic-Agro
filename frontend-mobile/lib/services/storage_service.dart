import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prediction_models.dart';

class StorageService {
  static const String _historyKey = 'prediction_history';

  Future<void> saveHistory(List<PredictionHistory> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<List<PredictionHistory>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => PredictionHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  Future<String> exportHistoryToCSV(List<PredictionHistory> history) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Timestamp,Crop,Confidence,N,P,K,Temperature,Humidity,pH');

    // Data
    for (final item in history) {
      buffer.write('${item.timestamp.toIso8601String()},');
      buffer.write('${item.crop},');
      buffer.write('${item.confidence},');
      buffer.write('${item.inputs['N']},');
      buffer.write('${item.inputs['P']},');
      buffer.write('${item.inputs['K']},');
      buffer.write('${item.inputs['temperature']},');
      buffer.write('${item.inputs['humidity']},');
      buffer.writeln('${item.inputs['pH']}');
    }

    return buffer.toString();
  }
}
