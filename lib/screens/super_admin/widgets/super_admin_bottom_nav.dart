import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../../constants/app_colors.dart';

class SuperAdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;

  const SuperAdminBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      onTap: onTap,
      backgroundColor: backgroundColor,
      color: AppColors.superAdminPrimary,
      buttonBackgroundColor: AppColors.superAdminPrimary,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      items: const [
        Icon(Icons.dashboard_rounded, color: Colors.white, size: 26),
        Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 26),
        Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 26),
        Icon(Icons.person_rounded, color: Colors.white, size: 26),
      ],
    );
  }
}
