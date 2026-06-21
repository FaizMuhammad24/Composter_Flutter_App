import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';
import 'admin_manage_admins_screen.dart';
import 'admin_manage_users_screen.dart';
import 'admin_manage_rewards_screen.dart';
import 'admin_deposit_approval_screen.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      _ManagementItem(
        title: 'Kelola Admins',
        subtitle: 'Tambah, edit & hapus admin',
        icon: Icons.shield_outlined,
        color: Colors.indigo,
        screen: const ManageAdminsScreen(),
      ),
      _ManagementItem(
        title: 'Kelola Users',
        subtitle: 'Lihat daftar user & deposit',
        icon: Icons.people_outlined,
        color: Colors.blue,
        screen: const ManageUsersScreen(),
      ),
      _ManagementItem(
        title: 'Kelola Rewards',
        subtitle: 'Buat & atur hadiah poin',
        icon: Icons.inventory_2_outlined,
        color: Colors.teal,
        screen: const ManageRewardsScreen(),
      ),
      _ManagementItem(
        title: 'Setoran Kompos',
        subtitle: 'Verifikasi input sampah user',
        icon: Icons.compost,
        color: Colors.green,
        screen: const AdminDepositApprovalScreen(),
      ),
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.adminPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dashboard_customize, color: AppColors.adminPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manajemen', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                  Text('Kelola sistem I-Compost', style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cards Grid
          ...items.map((item) => _buildManagementCard(context, item)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildManagementCard(BuildContext context, _ManagementItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(item.subtitle, style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagementItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  _ManagementItem({required this.title, required this.subtitle, required this.icon, required this.color, required this.screen});
}
