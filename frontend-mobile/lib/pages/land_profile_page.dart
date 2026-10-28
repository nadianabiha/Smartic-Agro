import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';

/// Profil pengukuran lahan V2. Data disimpan lokal sampai endpoint profil lahan
/// tersedia di backend V2.
class LandProfilePage extends StatefulWidget {
  const LandProfilePage({super.key});

  @override
  State<LandProfilePage> createState() => _LandProfilePageState();
}

class _LandProfilePageState extends State<LandProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _notes = TextEditingController();
  final Map<String, TextEditingController> _values = {
    'N': TextEditingController(),
    'P': TextEditingController(),
    'K': TextEditingController(),
    'pH': TextEditingController(),
    'Suhu (°C)': TextEditingController(),
    'Kelembapan (%)': TextEditingController(),
    'EC (mS/cm)': TextEditingController(),
  };
  bool _saving = false;
  bool _gettingLocation = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Aktifkan GPS perangkat terlebih dahulu.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi belum diberikan. Aktifkan izin lokasi untuk Smartic Agro.');
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      );
      _latitude.text = position.latitude.toStringAsFixed(6);
      _longitude.text = position.longitude.toStringAsFixed(6);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koordinat GPS berhasil diambil.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil GPS: $error')));
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _notes.dispose();
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite) return 'Masukkan angka yang valid';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getStringList('smartic_v2_land_profiles') ?? [];
      final entry = <String, dynamic>{
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'name': _name.text.trim(),
        'latitude': double.tryParse(_latitude.text.replaceAll(',', '.')),
        'longitude': double.tryParse(_longitude.text.replaceAll(',', '.')),
        'values': {
          for (final item in _values.entries)
            item.key: double.parse(item.value.text.replaceAll(',', '.')),
        },
        'notes': _notes.text.trim(),
        'source': 'input_manual',
        'device': 'Smartic Agro V2',
        'createdAt': DateTime.now().toIso8601String(),
      };
      previous.insert(0, jsonEncode(entry));
      await prefs.setStringList('smartic_v2_land_profiles', previous.take(100).toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil lahan disimpan di perangkat.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Detail Kondisi Lahan'),
        backgroundColor: AppColors.bgWhite,
        foregroundColor: AppColors.textDark,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.landscape, color: Colors.white, size: 30),
                  SizedBox(height: 10),
                  Text('Profil Lahan V2',
                      style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Catat kondisi lahan aktual sebelum rekomendasi tanaman.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle('Identitas dan lokasi'),
            _field(_name, 'Nama lahan / lokasi survei', Icons.place, required: true),
            Row(children: [
              Expanded(child: _field(_latitude, 'Latitude (opsional)', Icons.my_location)),
              const SizedBox(width: 10),
              Expanded(child: _field(_longitude, 'Longitude (opsional)', Icons.explore)),
            ]),
            OutlinedButton.icon(
              onPressed: _gettingLocation ? null : _useCurrentLocation,
              icon: _gettingLocation
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.gps_fixed),
              label: Text(_gettingLocation ? 'Mengambil lokasi...' : 'Gunakan Lokasi GPS Saat Ini'),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Parameter tanah dan lingkungan'),
            const Text('Masukkan nilai hasil sensor atau survei. Satuan mengikuti label.',
                style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 10),
            ..._values.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _field(entry.value, entry.key, Icons.sensors, required: true, numeric: true),
            )),
            _sectionTitle('Catatan survei'),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: lahan terbuka, setelah hujan, jenis tanah...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data profil disimpan lokal di perangkat dan belum tersinkron ke server. Gunakan data sensor atau hasil survei yang benar; jangan mengisi nilai perkiraan sebagai hasil pengukuran.',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan Profil Lahan'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      );

  Widget _field(TextEditingController controller, String label, IconData icon,
      {bool required = false, bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric || label.contains('Latitude') || label.contains('Longitude')
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        validator: required ? (numeric ? _validateNumber : (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null) : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          errorMaxLines: 2,
        ),
      ),
    );
  }


}
