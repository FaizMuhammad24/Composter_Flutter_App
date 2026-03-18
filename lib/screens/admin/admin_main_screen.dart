import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'admin_dashboard.dart';
import 'admin_history_log_screen.dart';
import 'admin_profile_screen.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_bottom_nav.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboard(),
    const AdminHistoryLogScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    String title = 'Admin I-Compost';
    if (_currentIndex == 1) title = 'History Log Alat';
    if (_currentIndex == 2) title = 'Profil Admin';

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AdminHeader(title: title),
      body: _pages[_currentIndex],
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
