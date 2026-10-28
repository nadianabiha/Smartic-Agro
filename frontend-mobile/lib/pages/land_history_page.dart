import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'dashboard_page.dart';

class LandHistoryPage extends StatefulWidget {
  const LandHistoryPage({super.key});

  @override
  State<LandHistoryPage> createState() => _LandHistoryPageState();
}

class _LandHistoryPageState extends State<LandHistoryPage> {
  static const _storageKey = 'smartic_v2_land_profiles';
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    final parsed = <Map<String, dynamic>>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) parsed.add(decoded);
      } catch (_) {
        // Ignore malformed legacy entries instead of breaking the history page.
      }
    }
    if (!mounted) return;
    setState(() {
      _profiles = parsed;
      _loading = false;
    });
  }

  Future<void> _delete(Map<String, dynamic> profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus riwayat?'),
        content: Text('Profil "${profile['name'] ?? 'Tanpa nama'}" akan dihapus dari perangkat ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    raw.removeWhere((item) {
      try { return jsonDecode(item)['id'] == profile['id']; } catch (_) { return false; }
    });
    await prefs.setStringList(_storageKey, raw);
    await _load();
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Waktu tidak tersedia';
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F2),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Column(children: [
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF178448))) : RefreshIndicator(onRefresh: _load, child: CustomScrollView(slivers: [
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 12), sliver: SliverToBoxAdapter(child: Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFDDF3E4), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.eco, color: Color(0xFF178448), size: 21)), const SizedBox(width: 9), const Text('Smartic Agro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF187443))), const Spacer(), IconButton(onPressed: _load, tooltip: 'Muat ulang', icon: const Icon(Icons.refresh, color: Color(0xFF187443)))]))),
          const SliverPadding(padding: EdgeInsets.fromLTRB(16, 8, 16, 0), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CATATAN PENGUKURAN', style: TextStyle(fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w800, color: Color(0xFF789083))), SizedBox(height: 5), Text('Histori', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF187443))), SizedBox(height: 5), Text('Riwayat hasil pengukuran dan data lahan Anda.', style: TextStyle(fontSize: 11, color: Color(0xFF84968A)))]))),
          if (!_loading && _profiles.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history, size: 52, color: Color(0xFF9BAAA0)), SizedBox(height: 12), Text('Belum ada riwayat pengukuran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF244532))), SizedBox(height: 6), Text('Simpan data dari halaman Detail Kondisi Lahan untuk melihat catatan di sini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF84968A)))])))),
          if (!_loading && _profiles.isNotEmpty) SliverPadding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 20), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
            final profile = _profiles[index];
            final values = Map<String, dynamic>.from(profile['values'] as Map? ?? {});
            final entries = values.entries.toList();
            return Container(margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1ECE4)), boxShadow: [BoxShadow(color: const Color(0xFF315A3E).withValues(alpha: .04), blurRadius: 8, offset: const Offset(0, 3))]), child: ExpansionTile(tilePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8), childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12), leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE7F5E9), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.eco, color: Color(0xFF21884D), size: 19)), title: Text(profile['name']?.toString().isNotEmpty == true ? profile['name'].toString() : 'Pengukuran lahan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF244532))), subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(_date(profile['createdAt']), style: const TextStyle(fontSize: 9, color: Color(0xFF84968A)))), trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F9185)), children: [if (entries.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: entries.map((e) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF0F7F2), borderRadius: BorderRadius.circular(8)), child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 10, color: Color(0xFF315A3E), fontWeight: FontWeight.w600)))).toList()), if (profile['latitude'] != null && profile['longitude'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: Text('GPS: ${profile['latitude']}, ${profile['longitude']}', style: const TextStyle(fontSize: 10, color: Color(0xFF84968A))))), if ((profile['notes'] ?? '').toString().trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Catatan: ${profile['notes']}', style: const TextStyle(fontSize: 11)))), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _delete(profile), icon: const Icon(Icons.delete_outline, size: 17), label: const Text('Hapus riwayat', style: TextStyle(fontSize: 11))))]));
          }, childCount: _profiles.length))),
        ]))),
        Container(height: 62, decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5EEE7)))), child: Row(children: [Expanded(child: _navItem(Icons.home_outlined, 'Home', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage())))), Expanded(child: _navItem(Icons.calendar_month, 'Histori', true, () {}))])),
      ]))))
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    final color = selected ? const Color(0xFF178448) : const Color(0xFF9BAAA0);
    return InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 19), const SizedBox(height: 3), Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)), if (selected) Container(margin: const EdgeInsets.only(top: 3), width: 18, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))) else const SizedBox(height: 5)]));
  }

}
