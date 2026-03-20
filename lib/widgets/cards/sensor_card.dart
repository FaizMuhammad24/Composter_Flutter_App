import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/styles/app_radius.dart';
import '../../utils/styles/app_elevation.dart';

/// 🌡️ Sensor Card Widget - Aplikasi Monitoring Kompos
/// Reusable card untuk menampilkan data sensor

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String status;
  final String? actuatorInfo;
  final IconData icon;
  final Color color;
  final double? valuePercent;
  final VoidCallback? onTap;
  final bool isActive;

  const SensorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    this.actuatorInfo,
    required this.icon,
    required this.color,
    this.valuePercent,
    this.onTap,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.md,
      shape: AppRadius.shapeMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Icon(icon, color: isActive ? color : Colors.grey[400], size: 36),
              const SizedBox(height: AppSpacing.xs),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Value
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isActive ? color : Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 14,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Progress Bar
              if (valuePercent != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: valuePercent,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),

              // Actuator Info (optional)
              if (actuatorInfo != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  actuatorInfo!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return AppColors.success;
      case 'tinggi':
      case 'rendah':
      case 'asam':
      case 'basa':
      case 'peringatan':
        return AppColors.warning;
      case 'bahaya':
      case 'danger':
      case 'gagal':
        return AppColors.error;
      case 'terputus':
      case 'offline':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }
}
