import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'super_admin_manage_admins_screen.dart';
import 'super_admin_manage_users_screen.dart';

/// ManagementScreen: combines Admin & User management in a single tabbed screen
class SuperAdminManagementScreen extends StatelessWidget {
  const SuperAdminManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.superAdminPrimary,
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
              tabs: [
                Tab(icon: Icon(Icons.shield_outlined, size: 18), text: 'Admin'),
                Tab(icon: Icon(Icons.people_outlined, size: 18), text: 'User'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ManageAdminsScreen(),
                ManageUsersScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
