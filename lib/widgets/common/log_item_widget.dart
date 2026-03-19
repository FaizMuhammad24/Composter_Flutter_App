import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/actuator_log_model.dart';
import '../../utils/helpers/date_formatter.dart';

/// 📝 Log Item Widget - Aplikasi Monitoring Kompos
/// Reusable widget untuk menampilkan item log dalam timeline

class LogItemWidget extends StatelessWidget {
  final ActuatorLogModel log;
  final bool isFirst;
  final bool isLast;

  const LogItemWidget({
    Key? key,
    required this.log,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOn = log.isOn;
    final statusColor = isOn ? AppColors.success : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 24,
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),

                // Circle indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOn ? statusColor : Colors.white,
                    border: Border.all(color: statusColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),

                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.textSecondary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp
                  Text(
                    DateFormatter.formatForLog(log.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Status
                  Row(
                    children: [
                      Icon(
                        isOn ? Icons.power : Icons.power_off,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sensor value (if available)
                  if (log.sensorValue != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.sensors,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Nilai sensor: ${log.sensorValueFormatted}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Reason
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          log.reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Duration (if ON)
                  if (isOn) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Durasi: ${log.durationDisplay}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
