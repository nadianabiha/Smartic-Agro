import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/prediction_models.dart';

class PredictionResultCard extends StatelessWidget {
  final PredictionResult result;
  final VoidCallback? onClose;

  const PredictionResultCard({
    super.key,
    required this.result,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hasil Prediksi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Top 3 Recommendations
            const Text(
              '3 Rekomendasi Tanaman Terbaik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // Recommendation 1 (Tertinggi)
            if (result.topCrops.isNotEmpty)
              _buildRecommendationCard(
                rank: 1,
                crop: result.topCrops[0].crop,
                confidence: result.topCrops[0].probability,
                color: AppColors.primary,
                isTop: true,
              ),
            if (result.topCrops.isNotEmpty) const SizedBox(height: 12),

            // Recommendation 2
            if (result.topCrops.length > 1)
              _buildRecommendationCard(
                rank: 2,
                crop: result.topCrops[1].crop,
                confidence: result.topCrops[1].probability,
                color: AppColors.accent,
                isTop: false,
              ),
            if (result.topCrops.length > 1) const SizedBox(height: 12),

            // Recommendation 3
            if (result.topCrops.length > 2)
              _buildRecommendationCard(
                rank: 3,
                crop: result.topCrops[2].crop,
                confidence: result.topCrops[2].probability,
                color: AppColors.secondary,
                isTop: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard({
    required int rank,
    required String crop,
    required double confidence,
    required Color color,
    required bool isTop,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isTop ? 0.2 : 0.1),
            color.withValues(alpha: isTop ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: isTop ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTop ? 18 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Crop Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.toUpperCase(),
                  style: TextStyle(
                    fontSize: isTop ? 20 : 18,
                    fontWeight: isTop ? FontWeight.bold : FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Tingkat kesesuaian',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Confidence Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${confidence.toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isTop ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
