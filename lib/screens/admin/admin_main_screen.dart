import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'dashboard/admin_dashboard.dart';
import 'control/admin_actuator_control_screen.dart';
import 'system/admin_system_status_screen.dart';
import 'profile/admin_profile_screen.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_bottom_nav.dart';
import '../../services/notifications/admin_notification_service.dart';
import '../../services/notifications/push_notification_service.dart';

import 'management/admin_management_screen.dart';

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
    _pages = [
      const AdminDashboard(),
      const AdminActuatorControlScreen(),
      const AdminSystemStatusScreen(),
      const AdminManagementScreen(),
      const AdminProfileScreen(),
    ];
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await AdminNotificationService().init(isAdmin: true);
    await PushNotificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Admin I-Compost';
    if (_currentIndex == 1) title = 'Kontrol Alat';
    if (_currentIndex == 2) title = 'Status Sistem';
    if (_currentIndex == 3) title = 'Manajemen';
    if (_currentIndex == 4) title = 'Profil Admin';

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
