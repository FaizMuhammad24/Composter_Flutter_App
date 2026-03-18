import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../../constants/app_colors.dart';

class UserBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color backgroundColor;

  const UserBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor = Colors.transparent, // Default transparent for dashboard
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 60.0,
      backgroundColor: backgroundColor,
      color: AppColors.primary,
      buttonBackgroundColor: AppColors.primary,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      items: const <Widget>[
        Icon(Icons.home, size: 30, color: Colors.white),
        Icon(Icons.history, size: 30, color: Colors.white),
        Icon(Icons.person_outline, size: 30, color: Colors.white),
      ],
      onTap: onTap,
    );
  }
}
