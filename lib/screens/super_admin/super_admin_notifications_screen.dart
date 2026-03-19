import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/mock_notifications.dart';
import '../../constants/app_colors.dart';

class SuperAdminNotificationsScreen extends StatefulWidget {
  const SuperAdminNotificationsScreen({Key? key}) : super(key: key);
  @override
  State<SuperAdminNotificationsScreen> createState() => _SuperAdminNotificationsScreenState();
}

class _SuperAdminNotificationsScreenState extends State<SuperAdminNotificationsScreen> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final allNotifs = MockNotifications.getAllNotifications();
    final filteredNotifs = _filter == 'Semua' 
        ? allNotifs 
        : (_filter == 'Belum Dibaca' 
            ? allNotifs.where((n) => !n.isRead).toList() 
            : allNotifs.where((n) => n.isRead).toList());

    return Scaffold(
      backgroundColor: AppColors.superAdminBg,
      appBar: AppBar(
        title: const Text('Notifikasi Super Admin', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.superAdminPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => MockNotifications.markAllAsRead());
            },
            child: const Text('Baca Semua', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Semua', 'Belum Dibaca', 'Sudah Dibaca'].map((cat) {
                final isSelected = _filter == cat;
                return InkWell(
                  onTap: () => setState(() => _filter = cat),
                  child: Column(
                    children: [
                      Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? AppColors.superAdminPrimary : Colors.grey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 2,
                        color: isSelected ? AppColors.superAdminPrimary : Colors.transparent,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Notifications List
          Expanded(
            child: filteredNotifs.isEmpty
                ? const Center(child: Text('Tidak ada notifikasi', style: TextStyle(fontFamily: 'Poppins')))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifs.length,
                    itemBuilder: (context, index) {
                      final notif = filteredNotifs[index];
                      return _buildNotifCard(notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(AdminNotification notif) {
    Color cardColor;
    IconData icon;
    Color iconColor;

    switch (notif.severity) {
      case 'danger':
        cardColor = Colors.red[50]!;
        icon = Icons.warning_rounded;
        iconColor = Colors.red;
        break;
      case 'warning':
        cardColor = Colors.orange[50]!;
        icon = Icons.error_outline_rounded;
        iconColor = Colors.orange;
        break;
      default:
        cardColor = Colors.blue[50]!;
        icon = Icons.info_outline_rounded;
        iconColor = Colors.blue;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: notif.isRead ? Colors.transparent : iconColor.withValues(alpha: 0.3)),
      ),
      color: notif.isRead ? Colors.white : cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins')),
            ),
            if (!notif.isRead)
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(notif.message, style: const TextStyle(fontSize: 13, height: 1.4, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(notif.timestamp),
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins'),
            ),
          ],
        ),
        onTap: () {
          setState(() => MockNotifications.markAsRead(notif.id));
        },
      ),
    );
  }
}
