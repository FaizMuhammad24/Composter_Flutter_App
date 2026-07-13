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
  final String? targetNote;
  final IconData icon;
  final Color color;
  final double? valuePercent;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isHorizontal;

  const SensorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    this.actuatorInfo,
    this.targetNote,
    required this.icon,
    required this.color,
    this.valuePercent,
    this.onTap,
    this.isActive = true,
    this.isHorizontal = false,
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
          padding: EdgeInsets.symmetric(
              horizontal: isHorizontal ? AppSpacing.md : AppSpacing.sm,
              vertical: isHorizontal ? AppSpacing.md : AppSpacing.sm),
          child: isHorizontal
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isActive ? color.withValues(alpha: 0.15) : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: isActive ? color : Colors.grey[400], size: 40),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'Poppins'),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                value,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isActive ? color : Colors.grey[600], fontFamily: 'Poppins'),
                              ),
                              if (unit.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(unit, style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.7))),
                              ],
                            ],
                          ),
                          if (valuePercent != null) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: AppRadius.borderRadiusSm,
                              child: LinearProgressIndicator(
                                value: valuePercent!.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey[300],
                                color: color,
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppRadius.borderRadiusSm,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? color : Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (targetNote != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            targetNote!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                        if (actuatorInfo != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            actuatorInfo!,
                            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              : Column(
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
                              color: color.withValues(alpha: 0.7),
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
                        borderRadius: AppRadius.borderRadiusSm,
                        child: LinearProgressIndicator(
                          value: valuePercent!.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          color: color,
                          minHeight: 4,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppRadius.borderRadiusSm,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? color : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    // Target Note
                    if (targetNote != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        targetNote!,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    // Actuator Info
                    if (actuatorInfo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        actuatorInfo!,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

}
