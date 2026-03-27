import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'admin_dashboard.dart';
import 'admin_compost_status_screen.dart';
import 'admin_system_status_screen.dart';
import 'admin_profile_screen.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_bottom_nav.dart';
import '../../services/notifications/admin_notification_service.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    AdminNotificationService().init();
    _pages = [
      const AdminDashboard(),
      const AdminCompostStatusScreen(),
      const AdminSystemStatusScreen(),
      const AdminProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Admin I-Compost';
    if (_currentIndex == 1) title = 'Status Kompos';
    if (_currentIndex == 2) title = 'Status Sistem';
    if (_currentIndex == 3) title = 'Profil Admin';

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AdminHeader(title: title),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _currentIndex,
        backgroundColor: AppColors.adminBg,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
