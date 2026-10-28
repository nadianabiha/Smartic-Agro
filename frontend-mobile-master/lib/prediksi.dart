import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:permission_handler/permission_handler.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROFESSIONAL COLOR SCHEME - TEAL, NAVY & GRAY
// ═══════════════════════════════════════════════════════════════════════════
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF0D7377); // Professional Teal
  static const Color primaryLight = Color(0xFF14919B);
  static const Color primaryDark = Color(0xFF084C54);
  // Secondary Colors
  static const Color secondary = Color(0xFF2C3E50); // Navy Blue
  static const Color secondaryLight = Color(0xFF34495E);
  // Accent & Status
  static const Color accent = Color(0xFF0FA3B1); // Bright Teal Accent
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  // Neutrals
  static const Color textDark = Color(0xFF1F2937); // Dark Gray
  static const Color textLight = Color(0xFF6B7280); // Medium Gray
  static const Color textHint = Color(0xFF9CA3AF); // Light Gray
  static const Color bgLight = Color(0xFFF9FAFB); // Very Light Gray
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB); // Border Gray
}

// ═══════════════════════════════════════════════════════════════════════════
class CropPredictionPage extends StatefulWidget {
  const CropPredictionPage({super.key});
  @override
  State<CropPredictionPage> createState() => _CropPredictionPageState();
}

class _CropPredictionPageState extends State<CropPredictionPage>
    with TickerProviderStateMixin {
  // ── Konstanta API ────────────────────────────────────────────────────────
  static const _pythonSensorApiUrl = 'http://localhost:5010/api/sensor/latest';
  static const _predictUrl = 'http://localhost:5010/predict';
  static const _pollInterval = Duration(seconds: 5);

  // ── Controller & State ───────────────────────────────────────────────────
  late final List<TextEditingController> _controllers;

  List<Map<String, dynamic>> _topCrops = [];
  List<Map<String, dynamic>> _history = [];

  bool _isPredicting = false;
  bool _showResult = false;
  bool _isLoadingSensor = false;
  bool _isLoadingLocation = false;

  Timer? _sensorTimer;
  final _logger = Logger('CropPrediction');
  int _sensorFailedCount = 0;
  String _mqttStatus = 'LOADING';

  // ── Animation Controllers ─────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _bounceAnim;

  // ── Sensor Configuration ───────────────────────
  final List<Map<String, dynamic>> _sensors = [
    {
      'key': 'N',
      'label': 'Nitrogen',
      'icon': Icons.grass,
      'color': AppColors.primary,
      'unit': ' mg/kg',
    },
    {
      'key': 'P',
      'label': 'Phosphor',
      'icon': Icons.eco,
      'color': AppColors.accent,
      'unit': ' mg/kg',
    },
    {
      'key': 'K',
      'label': 'Kalium',
      'icon': Icons.spa,
      'color': AppColors.secondary,
      'unit': ' mg/kg',
    },
    {
      'key': 'temperature',
      'label': 'Suhu',
      'icon': Icons.thermostat,
      'color': AppColors.warning,
      'unit': '°C',
    },
    {
      'key': 'humidity',
      'label': 'Kelembaban',
      'icon': Icons.water_drop,
      'color': AppColors.accent,
      'unit': '%',
    },
    {
      'key': 'ph',
      'label': 'pH Tanah',
      'icon': Icons.science,
      'color': AppColors.primary,
      'unit': '',
    },
  ];

  // ── Lifecycle Methods ───────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _sensors.length + 3, // 6 sensor + lat + lon + address
      (index) => TextEditingController(),
    );
    _controllers[_sensors.length + 2].text = 'Menunggu data lokasi...';

    _initAnimations();
    _setupLogging();
    _loadHistory();
    _startSensorPolling();
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut));
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -15).animate(
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticInOut));
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _pulseCtrl.dispose();
    _scaleCtrl.dispose();
    _bounceCtrl.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Logging Setup ──────────────────────────────────────────────────────
  void _setupLogging() {
    Logger.root.level = Level.ALL;
    PrintAppender().attachToLogger(Logger.root);
  }

  // ── Location & Permissions ─────────────────────────────────────────────
  Future<void> _requestPermissionsAndLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) {
        _showSnackBar(
            'Aktifkan layanan lokasi (GPS) terlebih dahulu', AppColors.warning,
            icon: Icons.location_disabled);
        setState(() => _isLoadingLocation = false);
        return;
      }

      final status = await Permission.location.request();
      if (status.isDenied) {
        _showSnackBar(
            'Izin lokasi diperlukan untuk deteksi lahan', AppColors.warning,
            icon: Icons.location_off);
        setState(() => _isLoadingLocation = false);
        return;
      }

      if (status.isPermanentlyDenied) {
        _showSnackBar(
            'Buka pengaturan untuk memberikan izin lokasi', AppColors.error,
            icon: Icons.settings,
            action: const SnackBarAction(
                label: 'Buka',
                textColor: Colors.white,
                onPressed: openAppSettings));
        setState(() => _isLoadingLocation = false);
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      _logger.severe(e);
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 10));

      final latCtrl = _controllers[_sensors.length];
      final lonCtrl = _controllers[_sensors.length + 1];
      final addrCtrl = _controllers[_sensors.length + 2];

      latCtrl.text = pos.latitude.toStringAsFixed(6);
      lonCtrl.text = pos.longitude.toStringAsFixed(6);

      final resp = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'SmartCropApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        addrCtrl.text = data['display_name'] ?? 'Lokasi tidak diketahui';
        _showSnackBar('Lokasi lahan ditemukan!', AppColors.success,
            icon: Icons.check_circle);
      } else {
        addrCtrl.text = 'Lat: ${latCtrl.text}, Lon: ${lonCtrl.text}';
      }
    } catch (e) {
      _logger.warning('Location fetch error: $e');
      _showSnackBar(
          'Gagal deteksi otomatis. Silakan input manual atau coba lagi.',
          AppColors.warning,
          icon: Icons.error);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showManualLocationDialog() {
    final latCtrl =
        TextEditingController(text: _controllers[_sensors.length].text);
    final lonCtrl =
        TextEditingController(text: _controllers[_sensors.length + 1].text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Lokasi Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(
                  labelText: 'Latitude', prefixIcon: Icon(Icons.north)),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonCtrl,
              decoration: const InputDecoration(
                  labelText: 'Longitude', prefixIcon: Icon(Icons.east)),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              _controllers[_sensors.length].text = latCtrl.text;
              _controllers[_sensors.length + 1].text = lonCtrl.text;
              _controllers[_sensors.length + 2].text =
                  'Lokasi Manual: ${latCtrl.text}, ${lonCtrl.text}';
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ── Sensor Polling ──────────────────────────────────────────────────────
  void _startSensorPolling() {
    _sensorTimer = Timer.periodic(
        _pollInterval, (Timer timer) => _fetchSensorData(isBackground: true));
    _fetchSensorData(isBackground: false);
  }

  Future<void> _fetchSensorData({bool isBackground = false}) async {
    if (_showResult || !mounted) return;

    if (!isBackground) {
      setState(() => _isLoadingSensor = true);
    }

    try {
      final resp = await http
          .get(Uri.parse(_pythonSensorApiUrl))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');

      _logger.info('Raw API Response: ${resp.body}');

      final jsonResponse = jsonDecode(resp.body) as Map<String, dynamic>;

      if (jsonResponse['status'] != 'success' ||
          !jsonResponse.containsKey('data')) {
        throw Exception('API Response Format Invalid or Data Empty');
      }

      final data = jsonResponse['data'] as Map<String, dynamic>;
      _logger.info('Parsed data: $data');

      if (mounted) {
        setState(() {
          for (int i = 0; i < _sensors.length; i++) {
            final sensorKey = _sensors[i]['key'] as String;
            final dynamic rawValue = data[sensorKey];

            _logger.info(
                'Processing sensor $sensorKey with value: $rawValue (${rawValue.runtimeType})');

            double value = 0.0;
            if (rawValue is num) {
              value = rawValue.toDouble();
            } else if (rawValue is String) {
              value = double.tryParse(rawValue) ?? 0.0;
            }

            // Format sesuai tipe sensor
            if (sensorKey == 'ph') {
              _controllers[i].text = value.toStringAsFixed(2);
            } else if (sensorKey == 'temperature' || sensorKey == 'humidity') {
              _controllers[i].text = value.toStringAsFixed(1);
            } else {
              _controllers[i].text = value.toStringAsFixed(1);
            }

            _logger.info(
                'Updated controller[$i] (${_sensors[i]['label']}): ${_controllers[i].text}');
          }

          final apiLat = data['lat'] is num
              ? (data['lat'] as num).toDouble()
              : double.tryParse(data['lat']?.toString() ?? '0') ?? 0.0;
          final apiLon = data['lon'] is num
              ? (data['lon'] as num).toDouble()
              : double.tryParse(data['lon']?.toString() ?? '0') ?? 0.0;

          if (apiLat != 0.0 && apiLon != 0.0) {
            _controllers[_sensors.length].text = apiLat.toStringAsFixed(6);
            _controllers[_sensors.length + 1].text = apiLon.toStringAsFixed(6);
            _reverseGeocodeSensorGPS(apiLat, apiLon);
          }

          // Update MQTT status dari backend
          _mqttStatus = data['status_mqtt']?.toString() ?? 'UNKNOWN';
        });
      }

      _sensorFailedCount = 0;
    } catch (e) {
      _sensorFailedCount++;
      _logger.warning('Sensor fetch error: $e');
      if (_sensorFailedCount >= 3 && !isBackground) {
        _showSnackBar(
            'Data sensor tidak tersedia (API Python Down).', AppColors.error,
            icon: Icons.error);
        _sensorFailedCount = 0;
      }
    } finally {
      if (!isBackground && mounted) {
        setState(() => _isLoadingSensor = false);
      }
    }
  }

  Future<void> _reverseGeocodeSensorGPS(double lat, double lon) async {
    final addrCtrl = _controllers[_sensors.length + 2];
    try {
      final resp = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'),
        headers: {'User-Agent': 'SmartCropApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final displayName = data['display_name'] ?? 'Lokasi tidak diketahui';
        if (mounted) {
          setState(() {
            addrCtrl.text =
                'Data Sensor GPS: $displayName (Lat $lat, Lon $lon)';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            addrCtrl.text =
                'Data Sensor GPS: Lat ${lat.toStringAsFixed(6)}, Lon ${lon.toStringAsFixed(6)}';
          });
        }
      }
    } catch (e) {
      _logger.warning('Reverse geocode error: $e');
      if (mounted) {
        setState(() {
          addrCtrl.text =
              'Data Sensor GPS: Lat ${lat.toStringAsFixed(6)}, Lon ${lon.toStringAsFixed(6)}';
        });
      }
    }
  }

  // ── Prediction Logic ────────────────────────────────────────────────────
  Future<void> _predictCrop() async {
    if (_controllers[0].text.isEmpty || _controllers[0].text == '0') {
      return _showSnackBar(
          'Tunggu hingga data sensor (N, P, K, dll.) tersedia dari perangkat.',
          AppColors.warning,
          icon: Icons.warning);
    }
    final lat = _controllers[_sensors.length].text;
    final lon = _controllers[_sensors.length + 1].text;

    if (lat.isEmpty ||
        lon.isEmpty ||
        double.tryParse(lat) == null ||
        double.tryParse(lon) == null) {
      return _showSnackBar(
          'Lokasi wajib diisi! Klik "Ambil Lokasi" atau input manual.',
          AppColors.warning,
          icon: Icons.location_off);
    }

    setState(() => _isPredicting = true);
    _scaleCtrl.forward().then((_) => _scaleCtrl.reverse());

    try {
      final body = <String, double>{};
      for (int i = 0; i < _sensors.length; i++) {
        body[_sensors[i]['key'] as String] =
            double.tryParse(_controllers[i].text) ?? 0;
      }

      _logger.info('Sending prediction request with body: $body');

      final resp = await http
          .post(
            Uri.parse(_predictUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _logger.info('Prediction response: $data');

        // Backend mengirim: prediction, confidence, second_prediction, second_confidence, third_prediction, third_confidence
        final String prediction = data['prediction']?.toString() ?? 'Unknown';
        final double confidence = _parseDouble(data['confidence']);
        final String secondPrediction =
            data['second_prediction']?.toString() ?? 'Unknown';
        final double secondConfidence = _parseDouble(data['second_confidence']);
        final String thirdPrediction =
            data['third_prediction']?.toString() ?? 'Unknown';
        final double thirdConfidence = _parseDouble(data['third_confidence']);

        final top1 = {'name': prediction, 'percentage': confidence};
        final top2 = {'name': secondPrediction, 'percentage': secondConfidence};
        final top3 = {'name': thirdPrediction, 'percentage': thirdConfidence};

        setState(() {
          _topCrops = [top1, top2, top3];
          _showResult = true;
        });

        final entry = <String, dynamic>{
          ...body.map((k, v) => MapEntry(k, v.toStringAsFixed(1))),
          'Latitude': lat,
          'Longitude': lon,
          'Address': _controllers[_sensors.length + 2].text,
          'Prediction': prediction,
          'Confidence': confidence.toStringAsFixed(1),
          'timestamp': DateTime.now().toIso8601String(),
        };

        _history.insert(0, entry);
        _saveHistory();
        _saveToFirebase(entry);

        _showSnackBar(
            'Prediksi berhasil: $prediction (${confidence.toStringAsFixed(1)}%)',
            AppColors.success,
            icon: Icons.check_circle);
      } else {
        _showSnackBar('Error server: ${resp.statusCode}', AppColors.error,
            icon: Icons.error);
      }
    } catch (e) {
      _logger.severe('Prediction error: $e');
      _showSnackBar('Prediksi gagal: $e', AppColors.error, icon: Icons.error);
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ── History & Firebase ─────────────────────────────────────────────────
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'crop_history', _history.map((e) => jsonEncode(e)).toList());
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('crop_history');
    if (list != null) {
      setState(() => _history = list
          .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
          .toList());
    }
  }

  Future<void> _saveToFirebase(Map<String, dynamic> entry) async {
    try {
      await FirebaseFirestore.instance.collection('prediksi').add({
        ...entry,
        for (var s in _sensors)
          if (entry.containsKey(s['key']))
            s['key'] as String:
                double.tryParse(entry[s['key']] as String) ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.warning('Firebase save failed: $e');
    }
  }

  Future<void> _exportHistory() async {
    if (_history.isEmpty) {
      return _showSnackBar('Riwayat prediksi masih kosong', AppColors.textHint,
          icon: Icons.history);
    }
    final csv = const ListToCsvConverter()
        .convert(_history.map((e) => e.values.toList()).toList());
    print('CSV Export: $csv');
    _showSnackBar('Riwayat telah diekspor ke CSV', AppColors.success,
        icon: Icons.download);
  }

  // ── Helper Methods ─────────────────────────────────────────────────────
  void _showSnackBar(String msg, Color color,
      {IconData? icon, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12)
          ],
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 8,
      action: action,
      duration: const Duration(seconds: 4),
    ));
  }

  Color _getMqttStatusColor(String status) {
    if (status.contains('CONNECTED')) return AppColors.success;
    if (status.contains('DISCONNECTED') ||
        status.contains('FAILED') ||
        status.contains('FATAL')) {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // UI WIDGETS
  // ═════════════════════════════════════════════════════════════════════════
  Widget _sensorCard(Map<String, dynamic> sensor, int idx) {
    final value = _controllers[idx].text;
    final parsed = double.tryParse(value);
    final hasData = parsed != null;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: sensor['color'].withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
                color: AppColors.bgWhite,
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (sensor['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(sensor['icon'], color: sensor['color'], size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sensor['label'],
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (hasData)
                    Text(
                      value + (sensor['unit'] ?? ''),
                      style: TextStyle(
                        color: sensor['color'],
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationCard() {
    final lat = _controllers[_sensors.length].text;
    final lon = _controllers[_sensors.length + 1].text;
    final addr = _controllers[_sensors.length + 2].text;

    final hasLocation = lat.isNotEmpty &&
        lon.isNotEmpty &&
        double.tryParse(lat) != null &&
        double.tryParse(lon) != null;

    final statusColor = _getMqttStatusColor(_mqttStatus);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: _pulseAnim.value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                            hasLocation
                                ? Icons.location_on
                                : Icons.location_off,
                            color: Colors.white,
                            size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Lahan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasLocation
                                  ? (addr.isNotEmpty ? addr : '$lat, $lon')
                                  : 'Data lokasi diperlukan untuk prediksi akurat.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (hasLocation && !_isLoadingLocation)
                        IconButton(
                          icon:
                              const Icon(Icons.refresh, color: Colors.white70),
                          onPressed: _requestPermissionsAndLocation,
                          tooltip: 'Update Lokasi',
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingLocation)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text("Mencari GPS...",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else if (!hasLocation)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _requestPermissionsAndLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text("Ambil Lokasi Saat Ini"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'Lat: $lat | Lon: $lon',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _showManualLocationDialog,
                            child: const Text(
                              "Edit Manual",
                              style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _mqttStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recommendationsSection() {
    if (!_showResult || _topCrops.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        color: AppColors.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rekomendasi Tanaman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._topCrops.asMap().entries.map((entry) {
            int index = entry.key;
            Map crop = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < _topCrops.length - 1 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      crop['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${crop['percentage'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return AppColors.primary;
      case 1:
        return AppColors.secondary;
      default:
        return AppColors.textLight;
    }
  }

  Widget _predictButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnim, _scaleAnim]),
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _isPredicting ? 0 : _bounceAnim.value),
        child: Transform.scale(
          scale: _isPredicting ? 1.0 : _scaleAnim.value,
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isPredicting ? null : _predictCrop,
              icon: _isPredicting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 22),
              label: Text(
                _isPredicting ? 'Menganalisis Data...' : 'Prediksi Sekarang',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainView() {
    final statusColor = _getMqttStatusColor(_mqttStatus);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sistem Prediksi',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Analisis Tanaman Cerdas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _mqttStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Data Sensor',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _sensors.length,
            itemBuilder: (context, index) {
              return _sensorCard(_sensors[index], index);
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Informasi Lokasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          _locationCard(),
          const SizedBox(height: 28),
          if (_showResult) ...[
            _recommendationsSection(),
            const SizedBox(height: 28),
          ],
          SizedBox(width: double.infinity, child: _predictButton()),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bgWhite,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Smart Crop Prediction',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textDark,
              letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            onPressed: _showHistoryBottomSheet,
            tooltip: 'Riwayat Prediksi',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => _fetchSensorData(isBackground: false),
            tooltip: 'Refresh Data Sensor',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _mainView(),
            if (_isLoadingSensor || _isPredicting)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Riwayat Prediksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _exportHistory,
                      icon:
                          const Icon(Icons.download, color: AppColors.primary),
                      tooltip: 'Ekspor',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox,
                                size: 48,
                                color:
                                    AppColors.textHint.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat prediksi',
                              style: TextStyle(
                                  color: AppColors.textLight, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: ctrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _history.length,
                        itemBuilder: (_, i) {
                          final h = _history[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: AppColors.border, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.eco,
                                    color: AppColors.primary, size: 20),
                              ),
                              title: Text(
                                h['Prediction'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${h['Confidence'] ?? '-'}% • ${h['temperature'] ?? '-'}°C • ${h['humidity'] ?? '-'}% • ${h['timestamp']?.substring(0, 16) ?? '-'}',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.share,
                                    color: AppColors.primary, size: 20),
                                onPressed: _exportHistory,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
