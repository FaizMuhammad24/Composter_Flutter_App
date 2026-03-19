import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../utils/styles/app_radius.dart';
import '../../utils/styles/app_elevation.dart';
import '../../models/reward_model.dart';

/// 🎁 Reward Card Widget - Aplikasi Monitoring Kompos
/// Reusable card untuk menampilkan item reward

class RewardCard extends StatelessWidget {
  final RewardModel reward;
  final int? userPoints;
  final VoidCallback? onTap;

  const RewardCard({
    Key? key,
    required this.reward,
    this.userPoints,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canRedeem = userPoints != null && reward.canRedeem(userPoints!);

    return Card(
      elevation: AppElevation.md,
      shape: AppRadius.shapeMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(),
                  size: 48,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    reward.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Points
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.points} poin',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category
                  Text(
                    reward.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canRedeem ? onTap : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRedeem
                            ? AppColors.success
                            : AppColors.textSecondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getButtonText(canRedeem),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (reward.category.toLowerCase()) {
      case 'voucher':
        return Icons.card_giftcard;
      case 'produk':
        return Icons.inventory_2_outlined;
      case 'merchandise':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.redeem;
    }
  }

  String _getButtonText(bool canRedeem) {
    if (!canRedeem && userPoints != null) return 'Poin Kurang';
    return 'Tukar';
  }
}
