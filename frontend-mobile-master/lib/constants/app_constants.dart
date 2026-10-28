import 'package:flutter/material.dart';

// Color scheme untuk aplikasi
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14919B);
  static const Color primaryDark = Color(0xFF084C54);

  // Secondary Colors
  static const Color secondary = Color(0xFF2C3E50);
  static const Color secondaryLight = Color(0xFF34495E);

  // Accent & Status
  static const Color accent = Color(0xFF0FA3B1);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  // Neutrals
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
}

// API Endpoints
class AppConstants {
  static const String sensorApiUrl = 'http://localhost:5010/api/sensor/latest';
  static const String predictUrl = 'http://localhost:5010/predict';
  static const Duration pollInterval = Duration(seconds: 5);
  static const int maxFailedAttempts = 3;
}

// Sensor configuration
class SensorConfig {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final String unit;

  const SensorConfig({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.unit,
  });

  static const List<SensorConfig> sensors = [
    SensorConfig(
      key: 'N',
      label: 'Nitrogen',
      icon: Icons.grass,
      color: AppColors.primary,
      unit: 'mg/kg',
    ),
    SensorConfig(
      key: 'P',
      label: 'Phosphor',
      icon: Icons.eco,
      color: AppColors.accent,
      unit: 'mg/kg',
    ),
    SensorConfig(
      key: 'K',
      label: 'Kalium',
      icon: Icons.spa,
      color: AppColors.secondary,
      unit: 'mg/kg',
    ),
    SensorConfig(
      key: 'temperature',
      label: 'Suhu',
      icon: Icons.thermostat,
      color: AppColors.warning,
      unit: '°C',
    ),
    SensorConfig(
      key: 'humidity',
      label: 'Kelembaban',
      icon: Icons.water_drop,
      color: AppColors.accent,
      unit: '%',
    ),
    SensorConfig(
      key: 'pH',
      label: 'pH Tanah',
      icon: Icons.science,
      color: AppColors.primary,
      unit: '',
    ),
  ];
}
