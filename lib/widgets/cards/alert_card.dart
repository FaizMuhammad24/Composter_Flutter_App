import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/styles/app_radius.dart';
import '../../utils/styles/app_elevation.dart';
import '../../models/alert_model.dart';

/// 🔔 Alert Card Widget - Aplikasi Monitoring Kompos
/// Reusable card untuk menampilkan notifikasi/alert

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AlertCard({
    Key? key,
    required this.alert,
    this.onTap,
    this.onDismiss,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              CircleAvatar(
                backgroundColor: _getAlertColor().withOpacity(0.2),
                child: Icon(
                  _getAlertIcon(),
                  color: _getAlertColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: alert.isRead
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Timestamp
                    Text(
                      alert.relativeTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing (read indicator or dismiss button)
              if (!alert.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getAlertColor(),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor() {
    switch (alert.type.toLowerCase()) {
      case 'temperature_high':
        return AppColors.temperature;
      case 'humidity_low':
        return AppColors.humidity;
      case 'ph_abnormal':
        return AppColors.ph;
      case 'gas_high':
        return AppColors.gas;
      default:
        return AppColors.warning;
    }
  }

  IconData _getAlertIcon() {
    switch (alert.type.toLowerCase()) {
      case 'temperature_high':
        return Icons.thermostat;
      case 'humidity_low':
        return Icons.water_drop;
      case 'ph_abnormal':
        return Icons.science;
      case 'gas_high':
        return Icons.air;
      default:
        return Icons.warning;
    }
  }
}
