import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/prediction_models.dart';

class HistoryWidget extends StatelessWidget {
  final List<PredictionHistory> history;
  final VoidCallback? onExport;
  final VoidCallback? onClear;

  const HistoryWidget({
    super.key,
    required this.history,
    this.onExport,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Prediksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Row(
              children: [
                if (onExport != null)
                  IconButton(
                    icon: const Icon(Icons.file_download, size: 20),
                    onPressed: history.isEmpty ? null : onExport,
                    tooltip: 'Export CSV',
                  ),
                if (onClear != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: history.isEmpty ? null : onClear,
                    tooltip: 'Hapus Riwayat',
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (history.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat prediksi',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length > 10 ? 10 : history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.agriculture,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.crop.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    '${item.confidence.toStringAsFixed(1)}% • ${_formatDate(item.timestamp)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textLight,
                  ),
                  onTap: () => _showDetailDialog(context, item),
                ),
              );
            },
          ),
        if (history.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {},
                child: Text('Lihat Semua (${history.length})'),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDetailDialog(BuildContext context, PredictionHistory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.crop.toUpperCase()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(
                  'Confidence', '${item.confidence.toStringAsFixed(1)}%'),
              _buildInfoRow('Tanggal', _formatDate(item.timestamp)),
              const Divider(height: 24),
              const Text(
                'Data Input:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              ...item.inputs.entries.map((e) => _buildInfoRow(
                    e.key,
                    e.value.toStringAsFixed(1),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textLight),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
