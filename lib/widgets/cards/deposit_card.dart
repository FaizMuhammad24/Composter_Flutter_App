import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/styles/app_radius.dart';
import '../../utils/styles/app_elevation.dart';
import '../../utils/helpers/date_formatter.dart';

/// 🗑️ Deposit Card Widget - Aplikasi Monitoring Kompos
/// Reusable card untuk menampilkan history deposit sampah

class DepositCard extends StatelessWidget {
  final String wasteType;
  final double weight;
  final int points;
  final String location;
  final DateTime timestamp;
  final bool hasImage;
  final VoidCallback? onTap;

  const DepositCard({
    Key? key,
    required this.wasteType,
    required this.weight,
    required this.points,
    required this.location,
    required this.timestamp,
    this.hasImage = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.sm,
      shape: AppRadius.shapeMd,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date & Points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.formatDateTime(timestamp),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$points poin',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Waste Type & Weight
              Row(
                children: [
                  const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$wasteType - ${weight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.image,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Location
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
