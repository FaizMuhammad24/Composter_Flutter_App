import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'super_admin_dashboard.dart';
import 'super_admin_manage_rewards_screen.dart';
import 'super_admin_management_screen.dart';
import 'super_admin_profile_screen.dart';
import 'widgets/super_admin_header.dart';
import 'widgets/super_admin_bottom_nav.dart';

class SuperAdminMainScreen extends StatefulWidget {
  const SuperAdminMainScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminMainScreen> createState() => _SuperAdminMainScreenState();
}

class _SuperAdminMainScreenState extends State<SuperAdminMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SuperAdminDashboard(onNavigate: (index) => setState(() => _currentIndex = index)),
      const ManageRewardsScreen(),
      const SuperAdminManagementScreen(),
      const SuperAdminProfileScreen(),
    ];

    String title = 'Super Admin';
    if (_currentIndex == 1) title = 'Kelola Hadiah';
    if (_currentIndex == 2) title = 'Manajemen';
    if (_currentIndex == 3) title = 'Profil';

    return Scaffold(
      backgroundColor: AppColors.superAdminBg,
      appBar: SuperAdminHeader(title: title),
      body: pages[_currentIndex],
      bottomNavigationBar: SuperAdminBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
