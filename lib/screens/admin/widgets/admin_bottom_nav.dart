import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../../constants/app_colors.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;

  const AdminBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 60.0,
      backgroundColor: backgroundColor,
      color: AppColors.adminPrimary,
      buttonBackgroundColor: AppColors.adminPrimary,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      items: const [
        Icon(Icons.home, size: 28, color: Colors.white),
        Icon(Icons.compost, size: 28, color: Colors.white),
        Icon(Icons.settings_suggest, size: 28, color: Colors.white),
        Icon(Icons.person, size: 28, color: Colors.white),
      ],
      onTap: onTap,
    );
  }
}
