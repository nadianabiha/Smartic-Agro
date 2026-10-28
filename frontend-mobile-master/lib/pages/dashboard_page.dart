import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../constants/app_constants.dart';
import '../models/prediction_models.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/sensor_monitoring_widget.dart';
import '../widgets/prediction_result_card.dart';
import '../widgets/history_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Services
  final _sensorService = SensorService();
  final _predictionService = PredictionService();
  final _locationService = LocationService();
  final _storageService = StorageService();

  // State
  SensorData? _sensorData;
  PredictionResult? _predictionResult;
  List<PredictionHistory> _history = [];
  bool _isLoadingSensor = false;
  bool _isPredicting = false;
  bool _showResult = false;
  DateTime _lastUpdate = DateTime.now();
  Timer? _sensorTimer;

  // Scroll Controller untuk maintain posisi scroll
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: true,
  );

  // Animation
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _init();
  }

  @override
  void dispose() {
    _sensorTimer?.cancel();
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadHistory();
    _startSensorPolling();
    _checkLocationPermission();
  }

  void _startSensorPolling() {
    // Cancel existing timer
    _sensorTimer?.cancel();

    _fetchSensorData();
    _sensorTimer = Timer.periodic(
      AppConstants.pollInterval,
      (_) => _fetchSensorData(),
    );
  }

  Future<void> _fetchSensorData() async {
    if (_showResult || _isPredicting || !mounted) return;

    // Update loading state tanpa rebuild
    _isLoadingSensor = true;

    final data = await _sensorService.fetchLatestSensorData();

    if (mounted && !_showResult && !_isPredicting) {
      // Update semua data sekaligus dalam satu setState untuk menghindari glitch
      setState(() {
        _sensorData = data;
        _lastUpdate = DateTime.now();
        _isLoadingSensor = false;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    final hasService = await _locationService.checkLocationService();
    if (!hasService) {
      _showSnackBar('Aktifkan layanan lokasi', AppColors.warning);
      return;
    }

    final status = await _locationService.requestLocationPermission();
    if (status == ph.PermissionStatus.denied ||
        status == ph.PermissionStatus.permanentlyDenied) {
      _showSnackBar('Izin lokasi diperlukan', AppColors.warning);
    }
  }

  Future<void> _predictCrop() async {
    if (_sensorData == null) {
      _showSnackBar('Menunggu data sensor...', AppColors.warning);
      return;
    }

    // Pause polling saat predict
    _sensorTimer?.cancel();

    setState(() {
      _isPredicting = true;
      _showResult = false;
    });

    final inputData = {
      'N': _sensorData!.n,
      'P': _sensorData!.p,
      'K': _sensorData!.k,
      'temperature': _sensorData!.temperature,
      'humidity': _sensorData!.humidity,
      'pH': _sensorData!.pH,
      'rainfall': 200.0, // Default value
    };

    final result = await _predictionService.predict(inputData);

    if (mounted) {
      setState(() {
        _isPredicting = false;
        _predictionResult = result;
        _showResult = result != null;
      });

      if (result != null) {
        _confettiController.play();
        _saveToHistory(result, inputData);
        _showSnackBar('Prediksi berhasil!', AppColors.success);
      } else {
        _showSnackBar('Gagal melakukan prediksi', AppColors.error);
      }
    }
  }

  Future<void> _saveToHistory(
    PredictionResult result,
    Map<String, double> inputs,
  ) async {
    final history = PredictionHistory(
      crop: result.crop,
      confidence: result.confidence,
      timestamp: DateTime.now(),
      inputs: inputs,
    );

    setState(() {
      _history.insert(0, history);
    });

    await _storageService.saveHistory(_history);
  }

  Future<void> _loadHistory() async {
    final history = await _storageService.loadHistory();
    setState(() => _history = history);
  }

  Future<void> _exportHistory() async {
    if (_history.isEmpty) return;

    final csv = await _storageService.exportHistoryToCSV(_history);
    // TODO: Save to file or share
    _showSnackBar('Export berhasil!', AppColors.success);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Crop Prediction'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchSensorData,
            child: SingleChildScrollView(
              key: const PageStorageKey('dashboard_scroll'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sensor Monitoring
                  SensorMonitoringWidget(
                    sensorData: _sensorData,
                    isLoading: _isLoadingSensor,
                    lastUpdate: _lastUpdate,
                    onRefresh: _fetchSensorData,
                  ),
                  const SizedBox(height: 24),

                  // Predict Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isPredicting ? null : _predictCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPredicting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.psychology),
                                SizedBox(width: 8),
                                Text(
                                  'Prediksi Tanaman',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Prediction Result
                  if (_showResult && _predictionResult != null)
                    PredictionResultCard(
                      result: _predictionResult!,
                      onClose: () {
                        setState(() => _showResult = false);
                        // Restart polling setelah close result
                        _startSensorPolling();
                      },
                    ),
                  if (_showResult) const SizedBox(height: 24),

                  // History
                  HistoryWidget(
                    history: _history,
                    onExport: _exportHistory,
                    onClear: () async {
                      await _storageService.clearHistory();
                      await _loadHistory();
                      _showSnackBar('Riwayat dihapus', AppColors.success);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.accent,
                AppColors.success,
                AppColors.warning,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
