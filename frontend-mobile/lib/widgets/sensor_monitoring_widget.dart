import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/prediction_models.dart';

class SensorMonitoringWidget extends StatelessWidget {
  final SensorData? sensorData;
  final bool isLoading;
  final DateTime lastUpdate;
  final VoidCallback onRefresh;

  const SensorMonitoringWidget({
    super.key,
    required this.sensorData,
    required this.isLoading,
    required this.lastUpdate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sensor Real-time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: sensorData?.mqttStatus == 'CONNECTED'
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: isLoading ? null : onRefresh,
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Update: ${_formatTime(lastUpdate)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (sensorData == null)
              const Center(
                child: Text(
                  'Tidak ada data sensor',
                  style: TextStyle(color: AppColors.textLight),
                ),
              )
            else
              _buildSensorGrid(sensorData!, context),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(SensorData data, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 64) / 2; // 64 = padding + spacing

    // Responsive font sizes based on card width - lebih besar
    final iconSize = cardWidth * 0.18;
    final labelFontSize = cardWidth * 0.10;
    final valueFontSize = cardWidth * 0.18;
    final unitFontSize = cardWidth * 0.10;

    final sensors = [
      {
        'label': 'Nitrogen',
        'value': data.n,
        'unit': 'mg/kg',
        'icon': Icons.grass,
        'color': AppColors.primary
      },
      {
        'label': 'Phosphor',
        'value': data.p,
        'unit': 'mg/kg',
        'icon': Icons.eco,
        'color': AppColors.accent
      },
      {
        'label': 'Kalium',
        'value': data.k,
        'unit': 'mg/kg',
        'icon': Icons.spa,
        'color': AppColors.secondary
      },
      {
        'label': 'Suhu',
        'value': data.temperature,
        'unit': '°C',
        'icon': Icons.thermostat,
        'color': AppColors.warning
      },
      {
        'label': 'Kelembaban',
        'value': data.humidity,
        'unit': '%',
        'icon': Icons.water_drop,
        'color': AppColors.accent
      },
      {
        'label': 'pH',
        'value': data.pH,
        'unit': '',
        'icon': Icons.science,
        'color': AppColors.primary
      },
      {
        'label': 'Latitude',
        'value': data.latitude,
        'unit': '°',
        'icon': Icons.explore,
        'color': AppColors.secondary
      },
      {
        'label': 'Longitude',
        'value': data.longitude,
        'unit': '°',
        'icon': Icons.explore_outlined,
        'color': AppColors.secondary
      },
      {
        'label': 'Altitude',
        'value': data.altitude,
        'unit': 'm',
        'icon': Icons.terrain,
        'color': AppColors.warning
      },
      {
        'label': 'Satelit',
        'value': data.satellites.toDouble(),
        'unit': '',
        'icon': Icons.satellite_alt,
        'color': AppColors.accent
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        return Container(
          padding: EdgeInsets.all(cardWidth * 0.08),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sensor['icon'] as IconData,
                color: sensor['color'] as Color,
                size: iconSize.clamp(24.0, 36.0),
              ),
              SizedBox(height: cardWidth * 0.08),
              Text(
                sensor['label'] as String,
                style: TextStyle(
                  fontSize: labelFontSize.clamp(11.0, 14.0),
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: cardWidth * 0.06),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                mainAxisAlignment: MainAxisAlignment.center,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    (sensor['value'] as double).toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: valueFontSize.clamp(20.0, 28.0),
                      fontWeight: FontWeight.bold,
                      color: sensor['color'] as Color,
                    ),
                  ),
                  if ((sensor['unit'] as String).isNotEmpty)
                    Text(
                      sensor['unit'] as String,
                      style: TextStyle(
                        fontSize: unitFontSize.clamp(11.0, 15.0),
                        color: sensor['color'] as Color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s yang lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m yang lalu';
    return '${diff.inHours}h yang lalu';
  }
}
