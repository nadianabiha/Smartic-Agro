// Models untuk data sensor dan prediksi
class SensorData {
  final double n;
  final double p;
  final double k;
  final double temperature;
  final double humidity;
  final double pH;
  final double ec;
  final double latitude;
  final double longitude;
  final double altitude;
  final int satellites;
  final double timestamp;
  final String mqttStatus;

  SensorData({
    required this.n,
    required this.p,
    required this.k,
    required this.temperature,
    required this.humidity,
    required this.pH,
    required this.ec,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.satellites,
    required this.timestamp,
    required this.mqttStatus,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      n: (json['N'] ?? 0).toDouble(),
      p: (json['P'] ?? 0).toDouble(),
      k: (json['K'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      pH: (json['pH'] ?? 0).toDouble(),
      ec: (json['ec'] ?? 0).toDouble(),
      latitude: (json['lat'] ?? 0).toDouble(),
      longitude: (json['lon'] ?? 0).toDouble(),
      altitude: (json['alt'] ?? 0).toDouble(),
      satellites: (json['sat'] ?? 0).toInt(),
      timestamp: (json['timestamp'] ?? 0).toDouble(),
      mqttStatus: json['status_mqtt'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'N': n,
      'P': p,
      'K': k,
      'temperature': temperature,
      'humidity': humidity,
      'pH': pH,
      'ec': ec,
      'lat': latitude,
      'lon': longitude,
      'alt': altitude,
      'sat': satellites,
      'timestamp': timestamp,
      'status_mqtt': mqttStatus,
    };
  }
}

class PredictionResult {
  final String crop;
  final double confidence;
  final List<CropRecommendation> topCrops;

  PredictionResult({
    required this.crop,
    required this.confidence,
    required this.topCrops,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // Ambil top_crops dari data jika ada
    List<CropRecommendation> topCropsList = [];

    if (json['data'] != null && json['data']['top_crops'] != null) {
      topCropsList = (json['data']['top_crops'] as List)
          .map((item) => CropRecommendation.fromJson(item))
          .toList();
    } else {
      // Fallback: buat dari field individual
      topCropsList = [
        CropRecommendation(
          crop: json['prediction'] ?? '',
          probability: (json['confidence'] ?? 0).toDouble(),
        ),
        if (json['second_prediction'] != null)
          CropRecommendation(
            crop: json['second_prediction'] ?? '',
            probability: (json['second_confidence'] ?? 0).toDouble(),
          ),
        if (json['third_prediction'] != null)
          CropRecommendation(
            crop: json['third_prediction'] ?? '',
            probability: (json['third_confidence'] ?? 0).toDouble(),
          ),
      ];
    }

    return PredictionResult(
      crop: json['prediction'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      topCrops: topCropsList,
    );
  }
}

class CropRecommendation {
  final String crop;
  final double probability;

  CropRecommendation({
    required this.crop,
    required this.probability,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      crop: json['crop'] ?? '',
      probability: (json['probability'] ?? 0).toDouble(),
    );
  }
}

class PredictionHistory {
  final String crop;
  final double confidence;
  final DateTime timestamp;
  final Map<String, double> inputs;

  PredictionHistory({
    required this.crop,
    required this.confidence,
    required this.timestamp,
    required this.inputs,
  });

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'inputs': inputs,
    };
  }

  factory PredictionHistory.fromJson(Map<String, dynamic> json) {
    return PredictionHistory(
      crop: json['crop'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      inputs: Map<String, double>.from(json['inputs'] ?? {}),
    );
  }
}
