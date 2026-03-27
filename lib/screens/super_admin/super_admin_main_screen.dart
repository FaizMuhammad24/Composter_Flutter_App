import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'super_admin_dashboard.dart';
import 'super_admin_manage_rewards_screen.dart';
import 'super_admin_management_screen.dart';
import 'super_admin_profile_screen.dart';
import 'widgets/super_admin_header.dart';
import 'widgets/super_admin_bottom_nav.dart';
import '../../services/auth/session_service.dart';
import '../../services/notifications/admin_notification_service.dart';

class SuperAdminMainScreen extends StatefulWidget {
  const SuperAdminMainScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminMainScreen> createState() => _SuperAdminMainScreenState();
}

class _SuperAdminMainScreenState extends State<SuperAdminMainScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    AdminNotificationService().init(isSuperAdmin: true);
    _pages = [
      SuperAdminDashboard(onNavigate: (index) => setState(() => _currentIndex = index)),
      const ManageRewardsScreen(),
      const SuperAdminManagementScreen(),
      const SuperAdminProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Super Admin';
    if (_currentIndex == 1) title = 'Kelola Hadiah';
    if (_currentIndex == 2) title = 'Manajemen';
    if (_currentIndex == 3) title = 'Profil';

    return Scaffold(
      // Always superAdminBg – the CurvedNavBar curves into this color.
      // The Profile screen handles its own red header internally.
      backgroundColor: AppColors.superAdminBg,
      appBar: SuperAdminHeader(
        title: title,
        adminEmail: SessionService.getCurrentUser()?.email ?? 'superadmin@icompost.com',
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SuperAdminBottomNav(
        currentIndex: _currentIndex,
        // Must match Scaffold backgroundColor so the curve looks seamless.
        backgroundColor: AppColors.superAdminBg,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
